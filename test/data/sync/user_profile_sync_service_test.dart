import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/user_profile_repository.dart';
import 'package:autolog/data/sync/remote_user_profile_source.dart';
import 'package:autolog/data/sync/user_profile_sync_facade.dart';
import 'package:autolog/data/sync/user_profile_sync_service.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/repositories/user_profile_repository.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — UserProfileSyncService (PK = userId, sem JOIN).

class FakeRemoteUserProfileSource implements RemoteUserProfileSource {
  final Map<String, UserProfile> store = {};
  DateTime? lastFetchSince;
  int fetchCallCount = 0;
  Set<String> failUpsertForUserIds = {};
  bool throwOnFetch = false;
  bool ignoreSince = false;

  void seed(UserProfile p) => store[p.userId] = p;

  @override
  Future<void> upsert(UserProfile profile) async {
    if (failUpsertForUserIds.contains(profile.userId)) {
      throw Exception('fake upsert failure for ${profile.userId}');
    }
    store[profile.userId] = profile;
  }

  @override
  Future<List<UserProfile>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    fetchCallCount++;
    lastFetchSince = since;
    if (throwOnFetch) throw Exception('fake fetch failure');
    final filtered = (since == null || ignoreSince)
        ? store.values
        : store.values.where((p) => p.updatedAt.isAfter(since));
    final list = filtered.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return list;
  }
}

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.UserProfileRepository profileRepo;
  late UserProfileSyncFacade facade;
  late FakeRemoteUserProfileSource remote;
  late UserProfileSyncService sync;

  DateTime now() => fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 25, 10);
    profileRepo = DriftUserProfileRepository(db, now: now);
    facade = DriftUserProfileSyncFacade(db);
    remote = FakeRemoteUserProfileSource();
    sync = UserProfileSyncService(facade: facade, remote: remote);
  });

  tearDown(() => db.close());

  UserProfile sample({
    String userId = 'u1',
    String? cnhNumber = '01234567891',
    String? cnhCategory = 'B',
    DateTime? updatedAt,
    SyncStatus syncStatus = SyncStatus.pending,
  }) {
    final d = fakeNow;
    return UserProfile(
      userId: userId,
      cnhNumber: cnhNumber,
      cnhCategory: cnhCategory,
      cnhExpiresAt: null,
      createdAt: d,
      updatedAt: updatedAt ?? d,
      syncStatus: syncStatus,
    );
  }

  group('push', () {
    test('envia pending, marca synced', () async {
      await profileRepo.getOrCreate('u1');
      final r = await sync.sync('u1');
      expect(remote.store['u1'], isNotNull);
      expect(r.pushed, 1);
      expect(
        (await profileRepo.getById('u1'))!.syncStatus,
        SyncStatus.synced,
      );
    });

    test('falha de push mantém pending', () async {
      await profileRepo.getOrCreate('u1');
      remote.failUpsertForUserIds = {'u1'};
      final r = await sync.sync('u1');
      expect(r.pushed, 0);
      expect(r.pushFailures, 1);
      expect(
        (await profileRepo.getById('u1'))!.syncStatus,
        SyncStatus.pending,
      );
    });
  });

  group('pull', () {
    test('insere/atualiza como synced', () async {
      remote.seed(sample(userId: 'u1', updatedAt: fakeNow));
      final r = await sync.sync('u1');
      expect(
        (await profileRepo.getById('u1'))!.syncStatus,
        SyncStatus.synced,
      );
      expect(r.pulled, 1);
    });

    test('cursor incremental', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 11);
      remote.seed(sample(userId: 'u1', updatedAt: t1));
      await sync.sync('u1');
      expect(remote.lastFetchSince, isNull);

      remote.seed(sample(userId: 'u1', cnhCategory: 'AB', updatedAt: t2));
      final r2 = await sync.sync('u1');
      expect(remote.lastFetchSince, t1);
      expect(r2.pulled, 1);
    });

    test('cursor inicial null sem nada synced', () async {
      await sync.sync('u1');
      expect(remote.lastFetchSince, isNull);
    });
  });

  group('conflito (LWW)', () {
    test('remoto mais novo vence', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);
      await facade.upsertFromRemote(sample(
        userId: 'u1',
        cnhCategory: 'B',
        updatedAt: t1,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(userId: 'u1', cnhCategory: 'AB', updatedAt: t2));
      final r = await sync.sync('u1');
      expect((await profileRepo.getById('u1'))!.cnhCategory, 'AB');
      expect(r.pulled, 1);
    });

    test('local mais novo preservado (guard LWW)', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);
      await facade.upsertFromRemote(sample(
        userId: 'u1',
        cnhCategory: 'AB',
        updatedAt: t2,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(userId: 'u1', cnhCategory: 'B', updatedAt: t1));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await profileRepo.getById('u1'))!.cnhCategory, 'AB');
      expect(r.pulled, 0);
    });

    test('empate updated_at: local vence', () async {
      final t = DateTime.utc(2026, 5, 25, 10);
      await facade.upsertFromRemote(sample(
        userId: 'u1',
        cnhCategory: 'B',
        updatedAt: t,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(userId: 'u1', cnhCategory: 'AB', updatedAt: t));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await profileRepo.getById('u1'))!.cnhCategory, 'B');
      expect(r.pulled, 0);
    });
  });

  group('erros', () {
    test('falha pull não vaza, push prévio preservado', () async {
      await profileRepo.getOrCreate('u1');
      remote.throwOnFetch = true;
      final r = await sync.sync('u1');
      expect(r.pushed, 1);
      expect(r.pulled, 0);
      expect(r.pullError, isNotNull);
      expect(
        (await profileRepo.getById('u1'))!.syncStatus,
        SyncStatus.synced,
      );
    });
  });
}
