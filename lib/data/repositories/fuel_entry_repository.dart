import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_fuel_entry_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// DriftFuelEntryRepository
// ---------------------------------------------------------------------------

/// Implementação local de [FuelEntryRepository] sobre Drift.
///
/// Recebe [AppDatabase] e um relógio opcional [now] para facilitar testes
/// determinísticos. Toda mutação grava localmente, marca sync_status=pending
/// e bumpa updated_at (Regra de Ouro: offline-first).
DateTime _utcNow() => DateTime.now().toUtc();

class DriftFuelEntryRepository implements FuelEntryRepository {
  DriftFuelEntryRepository(this._db, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  // -------------------------------------------------------------------------
  // create
  // -------------------------------------------------------------------------

  @override
  Future<FuelEntry> create(FuelEntry entry) async {
    final timestamp = _now();
    // Repositório sempre controla createdAt, updatedAt e sync_status.
    final companion = fuelEntryToCompanion(
      entry.copyWith(
        createdAt: timestamp,
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
        deletedAt: null,
      ),
    );

    await _db.into(_db.fuelEntries).insert(companion);

    final row = await (_db.select(
      _db.fuelEntries,
    )..where((t) => t.id.equals(entry.id))).getSingle();

    return fuelEntryToDomain(row);
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  @override
  Future<FuelEntry> update(FuelEntry entry) async {
    // Busca a linha incluindo soft-deleted para distinguir "não existe" de "deletado".
    final existing = await (_db.select(
      _db.fuelEntries,
    )..where((t) => t.id.equals(entry.id))).getSingleOrNull();

    if (existing == null) {
      throw StateError('Abastecimento não encontrado: ${entry.id}');
    }
    if (existing.deletedAt != null) {
      throw StateError(
        'Abastecimento soft-deletado não pode ser atualizado: ${entry.id}',
      );
    }

    final timestamp = _now();
    final companion = fuelEntryToCompanion(
      entry.copyWith(
        // Preserva createdAt original do banco.
        createdAt: existing.createdAt,
        // Repositório controla updated_at.
        updatedAt: timestamp,
        // Toda escrita local vira pending.
        syncStatus: SyncStatus.pending,
      ),
    );

    await (_db.update(
      _db.fuelEntries,
    )..where((t) => t.id.equals(entry.id))).write(companion);

    final row = await (_db.select(
      _db.fuelEntries,
    )..where((t) => t.id.equals(entry.id))).getSingle();

    return fuelEntryToDomain(row);
  }

  // -------------------------------------------------------------------------
  // softDelete
  // -------------------------------------------------------------------------

  @override
  Future<void> softDelete(String id) async {
    // Idempotente: se já deletado, preserva o deleted_at original.
    final existing = await (_db.select(
      _db.fuelEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing == null) return; // Não existe — nada a fazer.
    if (existing.deletedAt != null) return; // Já deletado — idempotente.

    final timestamp = _now();
    await (_db.update(_db.fuelEntries)..where((t) => t.id.equals(id))).write(
      FuelEntriesCompanion(
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
  Future<FuelEntry?> getById(String id) async {
    final row = await (_db.select(
      _db.fuelEntries,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();

    return row == null ? null : fuelEntryToDomain(row);
  }

  // -------------------------------------------------------------------------
  // listByVehicle
  // -------------------------------------------------------------------------

  @override
  Future<List<FuelEntry>> listByVehicle(String vehicleId) async {
    final rows =
        await (_db.select(_db.fuelEntries)
              ..where(
                (t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.date),
                (t) => OrderingTerm.desc(t.odometer),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();

    return rows.map(fuelEntryToDomain).toList();
  }

  // -------------------------------------------------------------------------
  // watchByVehicle
  // -------------------------------------------------------------------------

  @override
  Stream<List<FuelEntry>> watchByVehicle(String vehicleId) {
    return (_db.select(_db.fuelEntries)
          ..where((t) => t.vehicleId.equals(vehicleId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.odometer),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map(fuelEntryToDomain).toList());
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Expõe [DriftFuelEntryRepository] para o app.
final fuelEntryRepositoryProvider = Provider<FuelEntryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFuelEntryRepository(db);
});
