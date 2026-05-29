import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_reminder_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart';
import 'package:autolog/features/reminders/recurring/next_reminder_factory.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// DriftReminderRepository
// ---------------------------------------------------------------------------

/// Implementação local de [ReminderRepository] sobre Drift.
///
/// Recebe [AppDatabase] e um relógio opcional [now] para facilitar testes
/// determinísticos. Toda mutação grava localmente, marca sync_status=pending
/// e bumpa updated_at (Regra de Ouro: offline-first).
DateTime _utcNow() => DateTime.now().toUtc();

class DriftReminderRepository implements ReminderRepository {
  DriftReminderRepository(this._db, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  // -------------------------------------------------------------------------
  // create
  // -------------------------------------------------------------------------

  @override
  Future<Reminder> create(Reminder reminder) async {
    final timestamp = _now();
    // Repositório sempre controla createdAt, updatedAt e sync_status.
    final companion = reminderToCompanion(
      reminder.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
        deletedAt: null,
      ),
    );

    await _db.into(_db.reminders).insert(companion);

    final row = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(reminder.id))).getSingle();

    return reminderToDomain(row);
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  @override
  Future<Reminder> update(Reminder reminder) async {
    // Busca a linha incluindo soft-deleted para distinguir "não existe" de "deletado".
    final existing = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(reminder.id))).getSingleOrNull();

    if (existing == null) {
      throw StateError('Lembrete não encontrado: ${reminder.id}');
    }
    if (existing.deletedAt != null) {
      throw StateError(
        'Lembrete soft-deletado não pode ser atualizado: ${reminder.id}',
      );
    }

    final timestamp = _now();
    final companion = reminderToCompanion(
      reminder.copyWith(
        // Preserva createdAt original do banco.
        createdAt: existing.createdAt,
        // Repositório controla updated_at.
        updatedAt: timestamp,
        // Toda escrita local vira pending.
        syncStatus: SyncStatus.pending,
      ),
    );

    await (_db.update(
      _db.reminders,
    )..where((t) => t.id.equals(reminder.id))).write(companion);

    final row = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(reminder.id))).getSingle();

    return reminderToDomain(row);
  }

  // -------------------------------------------------------------------------
  // softDelete
  // -------------------------------------------------------------------------

  @override
  Future<void> softDelete(String id) async {
    // Idempotente: se já deletado, preserva o deleted_at original.
    final existing = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing == null) return; // Não existe — nada a fazer.
    if (existing.deletedAt != null) return; // Já deletado — idempotente.

    final timestamp = _now();
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      RemindersCompanion(
        deletedAt: Value(timestamp),
        updatedAt: Value(timestamp),
        syncStatus: const Value(SyncStatus.pending),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  @override
  Future<Reminder?> getById(String id) async {
    final row = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

    return row == null ? null : reminderToDomain(row);
  }

  // -------------------------------------------------------------------------
  // listByVehicle
  // -------------------------------------------------------------------------

  @override
  Future<List<Reminder>> listByVehicle(String vehicleId) async {
    final rows =
        await (_db.select(_db.reminders)
              ..where(
                (t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.isDone),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();

    return rows.map(reminderToDomain).toList();
  }

  // -------------------------------------------------------------------------
  // markDone
  // -------------------------------------------------------------------------

  @override
  Future<Reminder> markDone(
    String id, {
    int? currentOdometerKm,
    required DateTime now,
    required String Function() generateId,
  }) async {
    return _db.transaction<Reminder>(() async {
      // Carrega o lembrete atual (sem filtro de deletedAt para poder checar estado).
      final existing = await (_db.select(
        _db.reminders,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (existing == null) {
        throw StateError('Lembrete não encontrado: $id');
      }
      if (existing.deletedAt != null) {
        throw StateError('Lembrete soft-deletado não pode ser marcado: $id');
      }

      // Idempotência: já estava done → retorna sem criar duplicata.
      if (existing.isDone) {
        return reminderToDomain(existing);
      }

      final timestamp = _now();

      // Marca como done.
      await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(
          isDone: const Value(true),
          updatedAt: Value(timestamp),
          syncStatus: const Value(SyncStatus.pending),
        ),
      );

      final doneRow = await (_db.select(
        _db.reminders,
      )..where((t) => t.id.equals(id))).getSingle();
      final doneReminder = reminderToDomain(doneRow);

      // Tenta criar o próximo lembrete se houver intervalo.
      final next = createNextReminder(
        doneReminder: doneReminder,
        currentOdometerKm: currentOdometerKm,
        now: now,
        nextId: generateId(),
      );

      if (next != null) {
        final nextCompanion = reminderToCompanion(
          next.copyWith(
            createdAt: timestamp,
            updatedAt: timestamp,
            syncStatus: SyncStatus.pending,
          ),
        );
        await _db.into(_db.reminders).insert(nextCompanion);
      }

      return doneReminder;
    });
  }

  // -------------------------------------------------------------------------
  // watchByVehicle
  // -------------------------------------------------------------------------

  @override
  Stream<List<Reminder>> watchByVehicle(String vehicleId) {
    return (_db.select(_db.reminders)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.isDone),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map(reminderToDomain).toList());
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Expõe [DriftReminderRepository] para o app.
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftReminderRepository(db);
});
