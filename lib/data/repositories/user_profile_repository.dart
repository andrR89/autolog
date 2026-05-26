import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/_user_profile_mapper.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/repositories/user_profile_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// DriftUserProfileRepository
// ---------------------------------------------------------------------------

DateTime _utcNow() => DateTime.now().toUtc();

class DriftUserProfileRepository implements UserProfileRepository {
  DriftUserProfileRepository(this._db, {DateTime Function()? now})
    : _now = now ?? _utcNow;

  final AppDatabase _db;
  final DateTime Function() _now;

  // -------------------------------------------------------------------------
  // getById
  // -------------------------------------------------------------------------

  @override
  Future<UserProfile?> getById(String userId) async {
    final row = await (_db.select(
      _db.userProfile,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    return row == null ? null : userProfileToDomain(row);
  }

  // -------------------------------------------------------------------------
  // getOrCreate
  // -------------------------------------------------------------------------

  @override
  Future<UserProfile> getOrCreate(String userId) async {
    final existing = await getById(userId);
    if (existing != null) return existing;

    final timestamp = _now();
    final companion = UserProfileCompanion.insert(
      userId: userId,
      createdAt: timestamp,
      updatedAt: timestamp,
      syncStatus: const Value(SyncStatus.pending),
    );
    await _db.into(_db.userProfile).insert(companion);

    final row = await (_db.select(
      _db.userProfile,
    )..where((t) => t.userId.equals(userId))).getSingle();
    return userProfileToDomain(row);
  }

  // -------------------------------------------------------------------------
  // update
  // -------------------------------------------------------------------------

  @override
  Future<void> update(UserProfile profile) async {
    final timestamp = _now();
    final companion = userProfileToCompanion(
      profile.copyWith(
        updatedAt: timestamp,
        syncStatus: SyncStatus.pending,
      ),
    );
    await _db.into(_db.userProfile).insertOnConflictUpdate(companion);
  }

  // -------------------------------------------------------------------------
  // watch
  // -------------------------------------------------------------------------

  @override
  Stream<UserProfile?> watch(String userId) {
    return (_db.select(_db.userProfile)
          ..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : userProfileToDomain(row));
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftUserProfileRepository(db);
});
