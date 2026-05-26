import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/data/sync/reminder_sync_facade.dart';
import 'package:autolog/data/sync/reminder_sync_service.dart';
import 'package:autolog/data/sync/remote_reminder_source.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/reminder_repository.dart' as rdomain;
import 'package:autolog/domain/repositories/vehicle_repository.dart' as vdomain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 6.D-reminders — ReminderSyncService (mirror de 1.2 / 6.D-fuel / 6.D-expenses).

class FakeRemoteReminderSource implements RemoteReminderSource {
  final Map<String, Reminder> store = {};
  DateTime? lastFetchSince;
  String? lastFetchUserId;
  int fetchCallCount = 0;
  Set<String> failUpsertForIds = {};
  bool throwOnFetch = false;
  bool ignoreSince = false;

  void seed(Reminder r) => store[r.id] = r;

  @override
  Future<void> upsert(Reminder reminder) async {
    if (failUpsertForIds.contains(reminder.id)) {
      throw Exception('fake upsert failure for ${reminder.id}');
    }
    store[reminder.id] = reminder;
  }

  @override
  Future<List<Reminder>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    fetchCallCount++;
    lastFetchUserId = userId;
    lastFetchSince = since;
    if (throwOnFetch) throw Exception('fake fetch failure');
    final filtered = (since == null || ignoreSince)
        ? store.values
        : store.values.where((r) => r.updatedAt.isAfter(since));
    final list = filtered.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return list;
  }
}

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late vdomain.VehicleRepository vehicleRepo;
  late rdomain.ReminderRepository reminderRepo;
  late ReminderSyncFacade facade;
  late FakeRemoteReminderSource remote;
  late ReminderSyncService sync;

  DateTime now() => fakeNow;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 25, 10);
    vehicleRepo = DriftVehicleRepository(db, now: now);
    reminderRepo = DriftReminderRepository(db, now: now);
    facade = DriftReminderSyncFacade(db);
    remote = FakeRemoteReminderSource();
    sync = ReminderSyncService(facade: facade, remote: remote);

    await vehicleRepo.create(Vehicle(
      id: 'v1',
      userId: 'u1',
      nickname: 'Civic',
      fuelType: FuelType.gasolina,
      initialOdometer: 10000,
      createdAt: DateTime.utc(2000),
      updatedAt: DateTime.utc(2000),
      syncStatus: SyncStatus.synced,
    ));
  });

  tearDown(() => db.close());

  Reminder sample({
    String id = 'r1',
    String vehicleId = 'v1',
    String title = 'Troca de óleo',
    int? dueKm = 50000,
    DateTime? updatedAt,
    bool isDone = false,
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? deletedAt,
  }) {
    final d = fakeNow;
    return Reminder(
      id: id,
      vehicleId: vehicleId,
      type: ReminderType.porKm,
      title: title,
      dueKm: dueKm,
      isDone: isDone,
      createdAt: d,
      updatedAt: updatedAt ?? d,
      syncStatus: syncStatus,
      deletedAt: deletedAt,
    );
  }

  group('push', () {
    test('envia pending, marca synced', () async {
      await reminderRepo.create(sample());
      final r = await sync.sync('u1');
      expect(remote.store['r1'], isNotNull);
      expect(r.pushed, 1);
      expect(
        (await reminderRepo.getById('r1'))!.syncStatus,
        SyncStatus.synced,
      );
    });

    test('propaga soft-delete', () async {
      await reminderRepo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 25, 11);
      await reminderRepo.softDelete('r1');
      await sync.sync('u1');
      expect(remote.store['r1']!.deletedAt, isNotNull);
      final raw = await (db.select(
        db.reminders,
      )..where((t) => t.id.equals('r1'))).getSingle();
      expect(raw.syncStatus, SyncStatus.synced);
    });

    test('falha parcial', () async {
      await reminderRepo.create(sample(id: 'r1'));
      await reminderRepo.create(sample(id: 'r2'));
      await reminderRepo.create(sample(id: 'r3'));
      remote.failUpsertForIds = {'r2'};
      final r = await sync.sync('u1');
      expect(r.pushed, 2);
      expect(r.pushFailures, 1);
      expect(
        (await reminderRepo.getById('r2'))!.syncStatus,
        SyncStatus.pending,
      );
    });
  });

  group('pull', () {
    test('insere novo como synced', () async {
      remote.seed(sample(id: 'r1', updatedAt: fakeNow));
      final r = await sync.sync('u1');
      expect(
        (await reminderRepo.getById('r1'))!.syncStatus,
        SyncStatus.synced,
      );
      expect(r.pulled, 1);
    });

    test('cursor incremental', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 11);
      remote.seed(sample(id: 'r1', updatedAt: t1));
      await sync.sync('u1');
      expect(remote.lastFetchSince, isNull);
      remote.seed(sample(id: 'r2', updatedAt: t2));
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
        id: 'r1',
        title: 'Antigo',
        updatedAt: t1,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'r1', title: 'Novo', updatedAt: t2));
      final r = await sync.sync('u1');
      expect((await reminderRepo.getById('r1'))!.title, 'Novo');
      expect(r.pulled, 1);
    });

    test('local mais novo preservado (guard LWW)', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);
      await facade.upsertFromRemote(sample(
        id: 'r1',
        title: 'LocalNovo',
        updatedAt: t2,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'r1', title: 'RemotoAntigo', updatedAt: t1));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await reminderRepo.getById('r1'))!.title, 'LocalNovo');
      expect(r.pulled, 0);
    });

    test('empate updated_at: local vence', () async {
      final t = DateTime.utc(2026, 5, 25, 10);
      await facade.upsertFromRemote(sample(
        id: 'r1',
        title: 'Local',
        updatedAt: t,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'r1', title: 'Remoto', updatedAt: t));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await reminderRepo.getById('r1'))!.title, 'Local');
      expect(r.pulled, 0);
    });
  });

  group('isolamento por user via JOIN com vehicles', () {
    test('reminder de outro user NÃO aparece em listPending(u1)', () async {
      await vehicleRepo.create(Vehicle(
        id: 'v2',
        userId: 'u2',
        nickname: 'Outro',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2000),
        updatedAt: DateTime.utc(2000),
        syncStatus: SyncStatus.synced,
      ));
      await reminderRepo.create(sample(id: 'r_u1', vehicleId: 'v1'));
      await reminderRepo.create(sample(id: 'r_u2', vehicleId: 'v2'));

      expect((await facade.listPending('u1')).map((r) => r.id), ['r_u1']);
      expect((await facade.listPending('u2')).map((r) => r.id), ['r_u2']);
    });
  });

  group('erros', () {
    test('falha pull não vaza, push prévio preservado', () async {
      await reminderRepo.create(sample());
      remote.throwOnFetch = true;
      final r = await sync.sync('u1');
      expect(r.pushed, 1);
      expect(r.pulled, 0);
      expect(r.pullError, isNotNull);
      expect(
        (await reminderRepo.getById('r1'))!.syncStatus,
        SyncStatus.synced,
      );
    });
  });
}
