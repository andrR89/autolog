import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_insurance_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Fachada de sync para insurances — separa operações de sincronização da
/// API user-facing do [InsuranceRepository].
///
/// Filtra por user via JOIN com vehicles (insurances não tem user_id).
abstract class InsuranceSyncFacade {
  /// Lista todas as insurances pending do [userId], incluindo soft-deletadas.
  Future<List<Insurance>> listPending(String userId);

  /// Cursor de pull: max(updated_at) entre as synced do [userId].
  Future<DateTime?> latestSyncedUpdatedAt(String userId);

  /// Marca a insurance como synced.
  Future<void> markSynced(String id);

  /// Aplica o row vindo do remoto (upsert) e marca como synced.
  Future<void> upsertFromRemote(Insurance remote);

  /// Lê a insurance por [id] incluindo soft-deletadas.
  Future<Insurance?> getById(String id);

  /// Conta os pending do [userId].
  Future<int> countPending(String userId);

  /// Conta os pending do [userId] de forma reativa.
  Stream<int> watchPendingCount(String userId);
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

class DriftInsuranceSyncFacade implements InsuranceSyncFacade {
  DriftInsuranceSyncFacade(this._db);

  final AppDatabase _db;

  @override
  Future<List<Insurance>> listPending(String userId) async {
    final query =
        _db.select(_db.insurances).join([
          innerJoin(
            _db.vehicles,
            _db.vehicles.id.equalsExp(_db.insurances.vehicleId),
          ),
        ])..where(
          _db.vehicles.userId.equals(userId) &
              _db.insurances.syncStatus.equalsValue(SyncStatus.pending),
        );
    final rows = await query.get();
    return rows
        .map((row) => insuranceToDomain(row.readTable(_db.insurances)))
        .toList();
  }

  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async {
    final updatedAtCol = _db.insurances.updatedAt.max();
    final query =
        _db.selectOnly(_db.insurances).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.insurances.vehicleId),
            ),
          ])
          ..addColumns([updatedAtCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.insurances.syncStatus.equalsValue(SyncStatus.synced),
          );
    final row = await query.getSingleOrNull();
    return row?.read(updatedAtCol)?.toUtc();
  }

  @override
  Future<void> markSynced(String id) async {
    await (_db.update(_db.insurances)..where((t) => t.id.equals(id))).write(
      const InsurancesCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  @override
  Future<void> upsertFromRemote(Insurance remote) async {
    final companion = InsurancesCompanion.insert(
      id: remote.id,
      vehicleId: remote.vehicleId,
      insurer: Value(remote.insurer),
      policyNumber: Value(remote.policyNumber),
      startsAt: remote.startsAt,
      endsAt: remote.endsAt,
      premiumPaid: Value(remote.premiumPaid),
      notes: Value(remote.notes),
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      deletedAt: Value(remote.deletedAt),
      syncStatus: const Value(SyncStatus.synced),
    );
    await _db.into(_db.insurances).insertOnConflictUpdate(companion);
  }

  @override
  Future<Insurance?> getById(String id) async {
    final row = await (_db.select(
      _db.insurances,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : insuranceToDomain(row);
  }

  @override
  Future<int> countPending(String userId) async {
    final countCol = _db.insurances.id.count();
    final query =
        _db.selectOnly(_db.insurances).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.insurances.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.insurances.syncStatus.equalsValue(SyncStatus.pending),
          );
    final row = await query.getSingleOrNull();
    return row?.read(countCol) ?? 0;
  }

  @override
  Stream<int> watchPendingCount(String userId) {
    final countCol = _db.insurances.id.count();
    final query =
        _db.selectOnly(_db.insurances).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.insurances.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.insurances.syncStatus.equalsValue(SyncStatus.pending),
          );
    return query.watchSingle().map((row) => row.read(countCol) ?? 0);
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final insuranceSyncFacadeProvider = Provider<InsuranceSyncFacade>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftInsuranceSyncFacade(db);
});
