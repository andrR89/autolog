import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_reminder_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Fachada de sync para reminders — separa as operações de sincronização da
/// API user-facing do [ReminderRepository].
///
/// Esta interface bypassa a regra "toda escrita marca pending" — é exclusiva
/// do SyncService.
abstract class ReminderSyncFacade {
  /// Lista todos os reminders pending do [userId], incluindo soft-deletados
  /// (também precisam ser enviados ao remoto).
  /// Filtra por user via JOIN com vehicles (reminders não tem user_id).
  Future<List<Reminder>> listPending(String userId);

  /// Cursor de pull: max(updated_at) entre os synced do [userId].
  /// Retorna null se não houver nenhuma linha synced.
  /// Filtra por user via JOIN com vehicles.
  Future<DateTime?> latestSyncedUpdatedAt(String userId);

  /// Marca o reminder como synced sem alterar [updatedAt] nem qualquer outro campo.
  Future<void> markSynced(String id);

  /// Aplica o row vindo do remoto exatamente como veio (todos os campos,
  /// incluindo [updatedAt]), e marca como synced. Cria se não existir; atualiza
  /// se existir — nunca mantém valores velhos (campo-completeness garantida).
  Future<void> upsertFromRemote(Reminder remote);

  /// Lê o reminder bruto por [id] **incluindo soft-deletados**, para o
  /// SyncService comparar updated_at sem o filtro `deleted_at IS NULL` que o
  /// [ReminderRepository] aplica. Retorna null se não existir.
  Future<Reminder?> getById(String id);

  /// Conta os pending do [userId].
  /// Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
  /// Filtra por user via JOIN com vehicles.
  Future<int> countPending(String userId);

  /// Conta os pending do [userId] de forma reativa.
  /// Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
  /// Filtra por user via JOIN com vehicles.
  Stream<int> watchPendingCount(String userId);
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

/// Implementação de [ReminderSyncFacade] sobre [AppDatabase].
class DriftReminderSyncFacade implements ReminderSyncFacade {
  DriftReminderSyncFacade(this._db);

  final AppDatabase _db;

  // -----------------------------------------------------------------------
  // listPending
  // -----------------------------------------------------------------------

  @override
  Future<List<Reminder>> listPending(String userId) async {
    // JOIN com vehicles pra filtrar por userId — reminders não tem user_id.
    // Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
    final query =
        _db.select(_db.reminders).join([
          innerJoin(
            _db.vehicles,
            _db.vehicles.id.equalsExp(_db.reminders.vehicleId),
          ),
        ])..where(
          _db.vehicles.userId.equals(userId) &
              _db.reminders.syncStatus.equalsValue(SyncStatus.pending),
        );
    final rows = await query.get();
    return rows
        .map((row) => reminderToDomain(row.readTable(_db.reminders)))
        .toList();
  }

  // -----------------------------------------------------------------------
  // latestSyncedUpdatedAt
  // -----------------------------------------------------------------------

  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async {
    // SELECT max(updated_at) FROM reminders
    // JOIN vehicles ON vehicles.id = reminders.vehicle_id
    // WHERE vehicles.user_id = ? AND reminders.sync_status = 'synced'
    final updatedAtCol = _db.reminders.updatedAt.max();
    final query =
        _db.selectOnly(_db.reminders).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.reminders.vehicleId),
            ),
          ])
          ..addColumns([updatedAtCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.reminders.syncStatus.equalsValue(SyncStatus.synced),
          );
    final row = await query.getSingleOrNull();
    return row?.read(updatedAtCol)?.toUtc();
  }

  // -----------------------------------------------------------------------
  // markSynced
  // -----------------------------------------------------------------------

  @override
  Future<void> markSynced(String id) async {
    await (_db.update(_db.reminders)..where((t) => t.id.equals(id))).write(
      const RemindersCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  // -----------------------------------------------------------------------
  // upsertFromRemote
  // -----------------------------------------------------------------------

  @override
  Future<void> upsertFromRemote(Reminder remote) async {
    // Garante campo-completeness: todos os campos explícitos — nenhum
    // Value.absent() — para que INSERT e UPDATE não mantenham valores velhos.
    final companion = RemindersCompanion.insert(
      id: remote.id,
      vehicleId: remote.vehicleId,
      type: remote.type,
      title: remote.title,
      dueKm: Value(remote.dueKm),
      dueDate: Value(remote.dueDate),
      isDone: Value(remote.isDone),
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      deletedAt: Value(remote.deletedAt),
      syncStatus: const Value(SyncStatus.synced),
    );
    await _db.into(_db.reminders).insertOnConflictUpdate(companion);
  }

  // -----------------------------------------------------------------------
  // getById
  // -----------------------------------------------------------------------

  @override
  Future<Reminder?> getById(String id) async {
    // Sem filtro de deleted_at: o SyncService precisa enxergar soft-deletados
    // para o cálculo de last-write-wins.
    final row = await (_db.select(
      _db.reminders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : reminderToDomain(row);
  }

  // -----------------------------------------------------------------------
  // countPending
  // -----------------------------------------------------------------------

  @override
  Future<int> countPending(String userId) async {
    // SELECT count(id) FROM reminders
    // JOIN vehicles ON vehicles.id = reminders.vehicle_id
    // WHERE vehicles.user_id = ? AND reminders.sync_status = 'pending'
    // Sem filtro de deleted_at — soft-deletados pending também contam.
    final countCol = _db.reminders.id.count();
    final query =
        _db.selectOnly(_db.reminders).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.reminders.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.reminders.syncStatus.equalsValue(SyncStatus.pending),
          );
    final row = await query.getSingleOrNull();
    return row?.read(countCol) ?? 0;
  }

  // -----------------------------------------------------------------------
  // watchPendingCount
  // -----------------------------------------------------------------------

  @override
  Stream<int> watchPendingCount(String userId) {
    // SELECT count(id) FROM reminders
    // JOIN vehicles ON vehicles.id = reminders.vehicle_id
    // WHERE vehicles.user_id = ? AND reminders.sync_status = 'pending'
    // Sem filtro de deleted_at — soft-deletados pending também contam.
    final countCol = _db.reminders.id.count();
    final query =
        _db.selectOnly(_db.reminders).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.reminders.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.reminders.syncStatus.equalsValue(SyncStatus.pending),
          );
    return query.watchSingle().map((row) => row.read(countCol) ?? 0);
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final reminderSyncFacadeProvider = Provider<ReminderSyncFacade>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftReminderSyncFacade(db);
});
