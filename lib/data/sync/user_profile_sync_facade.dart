import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_user_profile_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Abstract contract
// ---------------------------------------------------------------------------

/// Fachada de sync para user_profile — separa operações de sincronização da
/// API user-facing do [UserProfileRepository].
///
/// PK = userId (não há JOIN com vehicles — RLS faz o filtro no servidor).
abstract class UserProfileSyncFacade {
  /// Lista todos os profiles pending do [userId].
  /// PK = userId, filtro direto.
  Future<List<UserProfile>> listPending(String userId);

  /// Cursor de pull: max(updated_at) do profile synced do [userId].
  /// Retorna null se não houver nenhuma linha synced.
  Future<DateTime?> latestSyncedUpdatedAt(String userId);

  /// Marca o profile como synced.
  Future<void> markSynced(String userId);

  /// Aplica o row vindo do remoto (upsert) e marca como synced.
  Future<void> upsertFromRemote(UserProfile remote);

  /// Lê o profile bruto por [userId].
  Future<UserProfile?> getById(String userId);

  /// Conta os pending do [userId].
  Future<int> countPending(String userId);

  /// Conta os pending de forma reativa.
  Stream<int> watchPendingCount(String userId);
}

// ---------------------------------------------------------------------------
// Drift implementation
// ---------------------------------------------------------------------------

class DriftUserProfileSyncFacade implements UserProfileSyncFacade {
  DriftUserProfileSyncFacade(this._db);

  final AppDatabase _db;

  @override
  Future<List<UserProfile>> listPending(String userId) async {
    // PK = userId: filtro direto, sem JOIN.
    final rows = await (_db.select(_db.userProfile)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.syncStatus.equalsValue(SyncStatus.pending),
          ))
        .get();
    return rows.map(userProfileToDomain).toList();
  }

  @override
  Future<DateTime?> latestSyncedUpdatedAt(String userId) async {
    final updatedAtCol = _db.userProfile.updatedAt.max();
    final query = _db.selectOnly(_db.userProfile)
      ..addColumns([updatedAtCol])
      ..where(
        _db.userProfile.userId.equals(userId) &
            _db.userProfile.syncStatus.equalsValue(SyncStatus.synced),
      );
    final row = await query.getSingleOrNull();
    return row?.read(updatedAtCol)?.toUtc();
  }

  @override
  Future<void> markSynced(String userId) async {
    await (_db.update(
      _db.userProfile,
    )..where((t) => t.userId.equals(userId))).write(
      const UserProfileCompanion(syncStatus: Value(SyncStatus.synced)),
    );
  }

  @override
  Future<void> upsertFromRemote(UserProfile remote) async {
    final companion = UserProfileCompanion.insert(
      userId: remote.userId,
      cnhNumber: Value(remote.cnhNumber),
      cnhCategory: Value(remote.cnhCategory),
      cnhExpiresAt: Value(remote.cnhExpiresAt),
      createdAt: remote.createdAt,
      updatedAt: remote.updatedAt,
      syncStatus: const Value(SyncStatus.synced),
    );
    await _db.into(_db.userProfile).insertOnConflictUpdate(companion);
  }

  @override
  Future<UserProfile?> getById(String userId) async {
    final row = await (_db.select(
      _db.userProfile,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    return row == null ? null : userProfileToDomain(row);
  }

  @override
  Future<int> countPending(String userId) async {
    final countCol = _db.userProfile.userId.count();
    final query = _db.selectOnly(_db.userProfile)
      ..addColumns([countCol])
      ..where(
        _db.userProfile.userId.equals(userId) &
            _db.userProfile.syncStatus.equalsValue(SyncStatus.pending),
      );
    final row = await query.getSingleOrNull();
    return row?.read(countCol) ?? 0;
  }

  @override
  Stream<int> watchPendingCount(String userId) {
    final countCol = _db.userProfile.userId.count();
    final query = _db.selectOnly(_db.userProfile)
      ..addColumns([countCol])
      ..where(
        _db.userProfile.userId.equals(userId) &
            _db.userProfile.syncStatus.equalsValue(SyncStatus.pending),
      );
    return query.watchSingle().map((row) => row.read(countCol) ?? 0);
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final userProfileSyncFacadeProvider = Provider<UserProfileSyncFacade>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftUserProfileSyncFacade(db);
});
