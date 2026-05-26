import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Fachada de sync para veículos — separa as operações de sincronização da
/// API user-facing do [VehicleRepository].
///
/// Esta interface bypassa a regra "toda escrita marca pending" — é exclusiva
/// do SyncService.
abstract class VehicleSyncFacade {
  /// Lista todos os veículos pending do [userId], incluindo soft-deletados
  /// (também precisam ser enviados ao remoto).
  Future<List<Vehicle>> listPending(String userId);

  /// Marca o veículo como synced sem alterar [updatedAt] nem qualquer outro campo.
  Future<void> markSynced(String id);

  /// Aplica o row vindo do remoto exatamente como veio (todos os campos,
  /// incluindo [updatedAt]), e marca como synced. Cria se não existir; atualiza
  /// se existir — nunca mantém valores velhos (campo-completeness garantida).
  Future<void> upsertFromRemote(Vehicle remote);

  /// Cursor de pull: max(updated_at) entre os synced do [userId].
  /// Retorna null se não houver nenhuma linha synced.
  Future<DateTime?> latestSyncedUpdatedAt(String userId);

  /// Lê o veículo bruto por [id] **incluindo soft-deletados**, para o
  /// SyncService comparar updated_at sem o filtro `deleted_at IS NULL` que o
  /// [VehicleRepository] aplica. Retorna null se não existir.
  Future<Vehicle?> getRawById(String id);

  /// Conta os pending do [userId] de forma reativa.
  /// Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
  Stream<int> watchPendingCount(String userId);
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

/// Implementação de [VehicleSyncFacade] sobre [AppDatabase].
class DriftVehicleSyncFacade implements VehicleSyncFacade {
  DriftVehicleSyncFacade(this._db);

  final AppDatabase _db;

  // -----------------------------------------------------------------------
  // listPending
  // -----------------------------------------------------------------------

  @override
  Future<List<Vehicle>> listPending(String userId) async {
    // Inclui soft-deletados (deleted_at IS NOT NULL) — também precisam subir.
    final rows =
        await (_db.select(_db.vehicles)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.syncStatus.equalsValue(SyncStatus.pending),
            ))
            .get();
    return rows.map(_toDomain).toList();
  }

  // -----------------------------------------------------------------------
  // markSynced
  // -----------------------------------------------------------------------

  @override
  Future<void> markSynced(String id) async {
    await (_db.update(_db.vehicles)..where((t) => t.id.equals(id))).write(
      const VehiclesCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  // -----------------------------------------------------------------------
  // upsertFromRemote
  // -----------------------------------------------------------------------

  @override
  Future<void> upsertFromRemote(Vehicle remote) async {
    // Garante campo-completeness: todos os campos explícitos — nenhum
    // Value.absent() — para que INSERT e UPDATE não mantenham valores velhos.
    final companion = VehiclesCompanion.insert(
      id: remote.id,
      userId: remote.userId,
      nickname: remote.nickname,
      make: Value(remote.make),
      model: Value(remote.model),
      plate: Value(remote.plate),
      fuelType: remote.fuelType,
      initialOdometer: remote.initialOdometer,
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      deletedAt: Value(remote.deletedAt),
      syncStatus: const Value(SyncStatus.synced),
    );

    await _db.into(_db.vehicles).insertOnConflictUpdate(companion);
  }

  // -----------------------------------------------------------------------
  // latestSyncedUpdatedAt
  // -----------------------------------------------------------------------

  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async {
    // SELECT max(updated_at) FROM vehicles WHERE user_id = ? AND sync_status = 'synced'
    final query = _db.selectOnly(_db.vehicles)
      ..addColumns([_db.vehicles.updatedAt.max()])
      ..where(
        _db.vehicles.userId.equals(userId) &
            _db.vehicles.syncStatus.equalsValue(SyncStatus.synced),
      );

    final row = await query.getSingleOrNull();
    final maxDt = row?.read(_db.vehicles.updatedAt.max());
    return maxDt?.toUtc();
  }

  // -----------------------------------------------------------------------
  // watchPendingCount
  // -----------------------------------------------------------------------

  @override
  Stream<int> watchPendingCount(String userId) {
    // SELECT count(id) FROM vehicles WHERE user_id = ? AND sync_status = 'pending'
    // Sem filtro de deleted_at — soft-deletados pending também contam.
    final countCol = _db.vehicles.id.count();
    final query = _db.selectOnly(_db.vehicles)
      ..addColumns([countCol])
      ..where(
        _db.vehicles.userId.equals(userId) &
            _db.vehicles.syncStatus.equalsValue(SyncStatus.pending),
      );
    return query.watchSingle().map((row) => row.read(countCol) ?? 0);
  }

  // -----------------------------------------------------------------------
  // getRawById
  // -----------------------------------------------------------------------

  @override
  Future<Vehicle?> getRawById(String id) async {
    // Sem filtro de deleted_at: o SyncService precisa enxergar soft-deletados
    // para o cálculo de last-write-wins.
    final row = await (_db.select(
      _db.vehicles,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }
}

// ---------------------------------------------------------------------------
// Helper mapper (local — não exposta fora deste arquivo)
// ---------------------------------------------------------------------------

Vehicle _toDomain(VehicleRow row) {
  return Vehicle(
    id: row.id,
    userId: row.userId,
    nickname: row.nickname,
    make: row.make,
    model: row.model,
    plate: row.plate,
    fuelType: row.fuelType,
    initialOdometer: row.initialOdometer,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    deletedAt: row.deletedAt?.toUtc(),
    syncStatus: row.syncStatus,
  );
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final vehicleSyncFacadeProvider = Provider<VehicleSyncFacade>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftVehicleSyncFacade(db);
});
