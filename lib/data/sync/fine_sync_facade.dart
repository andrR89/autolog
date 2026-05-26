import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_fine_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Fachada de sync para fines — separa operações de sincronização da
/// API user-facing do [FineRepository].
///
/// Filtra por user via JOIN com vehicles (fines não tem user_id).
abstract class FineSyncFacade {
  /// Lista todas as fines pending do [userId], incluindo soft-deletadas.
  Future<List<Fine>> listPending(String userId);

  /// Cursor de pull: max(updated_at) entre as synced do [userId].
  Future<DateTime?> latestSyncedUpdatedAt(String userId);

  /// Marca a fine como synced.
  Future<void> markSynced(String id);

  /// Aplica o row vindo do remoto (upsert) e marca como synced.
  Future<void> upsertFromRemote(Fine remote);

  /// Lê a fine por [id] incluindo soft-deletadas.
  Future<Fine?> getById(String id);

  /// Conta os pending do [userId].
  Future<int> countPending(String userId);

  /// Conta os pending do [userId] de forma reativa.
  Stream<int> watchPendingCount(String userId);
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

class DriftFineSyncFacade implements FineSyncFacade {
  DriftFineSyncFacade(this._db);

  final AppDatabase _db;

  @override
  Future<List<Fine>> listPending(String userId) async {
    final query =
        _db.select(_db.fines).join([
          innerJoin(
            _db.vehicles,
            _db.vehicles.id.equalsExp(_db.fines.vehicleId),
          ),
        ])..where(
          _db.vehicles.userId.equals(userId) &
              _db.fines.syncStatus.equalsValue(SyncStatus.pending),
        );
    final rows = await query.get();
    return rows.map((row) => fineToDomain(row.readTable(_db.fines))).toList();
  }

  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async {
    final updatedAtCol = _db.fines.updatedAt.max();
    final query =
        _db.selectOnly(_db.fines).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.fines.vehicleId),
            ),
          ])
          ..addColumns([updatedAtCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.fines.syncStatus.equalsValue(SyncStatus.synced),
          );
    final row = await query.getSingleOrNull();
    return row?.read(updatedAtCol)?.toUtc();
  }

  @override
  Future<void> markSynced(String id) async {
    await (_db.update(_db.fines)..where((t) => t.id.equals(id))).write(
      const FinesCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  @override
  Future<void> upsertFromRemote(Fine remote) async {
    final companion = FinesCompanion.insert(
      id: remote.id,
      vehicleId: remote.vehicleId,
      autoNumber: Value(remote.autoNumber),
      issuedAt: remote.issuedAt,
      description: remote.description,
      amount: remote.amount,
      dueDate: Value(remote.dueDate),
      paid: Value(remote.paid),
      points: Value(remote.points),
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      deletedAt: Value(remote.deletedAt),
      syncStatus: const Value(SyncStatus.synced),
    );
    await _db.into(_db.fines).insertOnConflictUpdate(companion);
  }

  @override
  Future<Fine?> getById(String id) async {
    final row = await (_db.select(
      _db.fines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : fineToDomain(row);
  }

  @override
  Future<int> countPending(String userId) async {
    final countCol = _db.fines.id.count();
    final query =
        _db.selectOnly(_db.fines).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.fines.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.fines.syncStatus.equalsValue(SyncStatus.pending),
          );
    final row = await query.getSingleOrNull();
    return row?.read(countCol) ?? 0;
  }

  @override
  Stream<int> watchPendingCount(String userId) {
    final countCol = _db.fines.id.count();
    final query =
        _db.selectOnly(_db.fines).join([
            innerJoin(
              _db.vehicles,
              _db.vehicles.id.equalsExp(_db.fines.vehicleId),
            ),
          ])
          ..addColumns([countCol])
          ..where(
            _db.vehicles.userId.equals(userId) &
                _db.fines.syncStatus.equalsValue(SyncStatus.pending),
          );
    return query.watchSingle().map((row) => row.read(countCol) ?? 0);
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final fineSyncFacadeProvider = Provider<FineSyncFacade>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFineSyncFacade(db);
});
