import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_fuel_entry_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Fachada de sync para fuel_entries — separa as operações de sincronização da
/// API user-facing do [FuelEntryRepository].
///
/// Esta interface bypassa a regra "toda escrita marca pending" — é exclusiva
/// do SyncService.
abstract class FuelEntrySyncFacade {
  /// Lista todos os fuel_entries pending do [userId], incluindo soft-deletados
  /// (também precisam ser enviados ao remoto).
  /// Filtra por user via JOIN com vehicles (fuel_entries não tem user_id).
  Future<List<FuelEntry>> listPending(String userId);

  /// Marca o fuel_entry como synced sem alterar [updatedAt] nem qualquer outro campo.
  Future<void> markSynced(String id);

  /// Aplica o row vindo do remoto exatamente como veio (todos os campos,
  /// incluindo [updatedAt]), e marca como synced. Cria se não existir; atualiza
  /// se existir — nunca mantém valores velhos (campo-completeness garantida).
  Future<void> upsertFromRemote(FuelEntry remote);

  /// Cursor de pull: max(updated_at) entre os synced do [userId].
  /// Retorna null se não houver nenhuma linha synced.
  /// Filtra por user via JOIN com vehicles.
  Future<DateTime?> latestSyncedUpdatedAt(String userId);

  /// Lê o fuel_entry bruto por [id] **incluindo soft-deletados**, para o
  /// SyncService comparar updated_at sem o filtro `deleted_at IS NULL` que o
  /// [FuelEntryRepository] aplica. Retorna null se não existir.
  Future<FuelEntry?> getRawById(String id);

  /// Conta os pending do [userId] de forma reativa.
  /// Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
  /// Filtra por user via JOIN com vehicles.
  Stream<int> watchPendingCount(String userId);
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

/// Implementação de [FuelEntrySyncFacade] sobre [AppDatabase].
class DriftFuelEntrySyncFacade implements FuelEntrySyncFacade {
  DriftFuelEntrySyncFacade(this._db);

  final AppDatabase _db;

  // -----------------------------------------------------------------------
  // listPending
  // -----------------------------------------------------------------------

  @override
  Future<List<FuelEntry>> listPending(String userId) async {
    // JOIN com vehicles pra filtrar por userId — fuel_entries não tem user_id.
    // Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
    final query =
        _db.select(_db.fuelEntries).join([
          innerJoin(
            _db.vehicles,
            _db.vehicles.id.equalsExp(_db.fuelEntries.vehicleId),
          ),
        ])..where(
          _db.vehicles.userId.equals(userId) &
              _db.fuelEntries.syncStatus.equalsValue(SyncStatus.pending),
        );
    final rows = await query.get();
    return rows
        .map((row) => fuelEntryToDomain(row.readTable(_db.fuelEntries)))
        .toList();
  }

  // -----------------------------------------------------------------------
  // markSynced
  // -----------------------------------------------------------------------

  @override
  Future<void> markSynced(String id) async {
    await (_db.update(_db.fuelEntries)..where((t) => t.id.equals(id))).write(
      const FuelEntriesCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  // -----------------------------------------------------------------------
  // upsertFromRemote
  // -----------------------------------------------------------------------

  @override
  Future<void> upsertFromRemote(FuelEntry remote) async {
    // Garante campo-completeness: todos os campos explícitos — nenhum
    // Value.absent() — para que INSERT e UPDATE não mantenham valores velhos.
    final companion = FuelEntriesCompanion.insert(
      id: remote.id,
      vehicleId: remote.vehicleId,
      date: remote.date,
      odometer: remote.odometer,
      liters: remote.liters,
      pricePerLiter: remote.pricePerLiter,
      totalCost: remote.totalCost,
      fullTank: remote.fullTank,
      fuelType: remote.fuelType,
      source: remote.source,
      receiptImageUrl: Value(remote.receiptImageUrl),
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      deletedAt: Value(remote.deletedAt),
      syncStatus: const Value(SyncStatus.synced),
    );
    await _db.into(_db.fuelEntries).insertOnConflictUpdate(companion);
  }

  // -----------------------------------------------------------------------
  // latestSyncedUpdatedAt
  // -----------------------------------------------------------------------

  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async {
    // SELECT max(updated_at) FROM fuel_entries
    // JOIN vehicles ON vehicles.id = fuel_entries.vehicle_id
    // WHERE vehicles.user_id = ? AND fuel_entries.sync_status = 'synced'
    final updatedAtCol = _db.fuelEntries.updatedAt.max();
    final query =
        _db.selectOnly(_db.fuelEntries).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.fuelEntries.vehicleId),
            ),
          ])
          ..addColumns([updatedAtCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.fuelEntries.syncStatus.equalsValue(SyncStatus.synced),
          );
    final row = await query.getSingleOrNull();
    return row?.read(updatedAtCol)?.toUtc();
  }

  // -----------------------------------------------------------------------
  // getRawById
  // -----------------------------------------------------------------------

  @override
  Future<FuelEntry?> getRawById(String id) async {
    // Sem filtro de deleted_at: o SyncService precisa enxergar soft-deletados
    // para o cálculo de last-write-wins.
    final row = await (_db.select(
      _db.fuelEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : fuelEntryToDomain(row);
  }

  // -----------------------------------------------------------------------
  // watchPendingCount
  // -----------------------------------------------------------------------

  @override
  Stream<int> watchPendingCount(String userId) {
    // SELECT count(id) FROM fuel_entries
    // JOIN vehicles ON vehicles.id = fuel_entries.vehicle_id
    // WHERE vehicles.user_id = ? AND fuel_entries.sync_status = 'pending'
    // Sem filtro de deleted_at — soft-deletados pending também contam.
    final countCol = _db.fuelEntries.id.count();
    final query =
        _db.selectOnly(_db.fuelEntries).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.fuelEntries.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.fuelEntries.syncStatus.equalsValue(SyncStatus.pending),
          );
    return query.watchSingle().map((row) => row.read(countCol) ?? 0);
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final fuelEntrySyncFacadeProvider = Provider<FuelEntrySyncFacade>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFuelEntrySyncFacade(db);
});
