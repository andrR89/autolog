import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/fine_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/data/sync/fine_sync_facade.dart';
import 'package:autolog/data/sync/fine_sync_service.dart';
import 'package:autolog/data/sync/remote_fine_source.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/fine_repository.dart' as fdomain;
import 'package:autolog/domain/repositories/vehicle_repository.dart' as vdomain;
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — FineSyncService (mirror de reminder_sync_service_test).

class FakeRemoteFineSource implements RemoteFineSource {
  final Map<String, Fine> store = {};
  DateTime? lastFetchSince;
  String? lastFetchUserId;
  int fetchCallCount = 0;
  Set<String> failUpsertForIds = {};
  bool throwOnFetch = false;
  bool ignoreSince = false;

  void seed(Fine f) => store[f.id] = f;

  @override
  Future<void> upsert(Fine fine) async {
    if (failUpsertForIds.contains(fine.id)) {
      throw Exception('fake upsert failure for ${fine.id}');
    }
    store[fine.id] = fine;
  }

  @override
  Future<List<Fine>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    fetchCallCount++;
    lastFetchUserId = userId;
    lastFetchSince = since;
    if (throwOnFetch) throw Exception('fake fetch failure');
    final filtered = (since == null || ignoreSince)
        ? store.values
        : store.values.where((f) => f.updatedAt.isAfter(since));
    final list = filtered.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return list;
  }
}

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late vdomain.VehicleRepository vehicleRepo;
  late fdomain.FineRepository fineRepo;
  late FineSyncFacade facade;
  late FakeRemoteFineSource remote;
  late FineSyncService sync;

  DateTime now() => fakeNow;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 25, 10);
    vehicleRepo = DriftVehicleRepository(db, now: now);
    fineRepo = DriftFineRepository(db, now: now);
    facade = DriftFineSyncFacade(db);
    remote = FakeRemoteFineSource();
    sync = FineSyncService(facade: facade, remote: remote);

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

  Fine sample({
    String id = 'f1',
    String vehicleId = 'v1',
    String description = 'Excesso de velocidade',
    DateTime? updatedAt,
    bool paid = false,
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? deletedAt,
  }) {
    final d = fakeNow;
    return Fine(
      id: id,
      vehicleId: vehicleId,
      autoNumber: null,
      issuedAt: d,
      description: description,
      amount: Decimal.parse('293.47'),
      dueDate: null,
      paid: paid,
      points: null,
      createdAt: d,
      updatedAt: updatedAt ?? d,
      syncStatus: syncStatus,
      deletedAt: deletedAt,
    );
  }

  group('push', () {
    test('envia pending, marca synced', () async {
      await fineRepo.create(sample());
      final r = await sync.sync('u1');
      expect(remote.store['f1'], isNotNull);
      expect(r.pushed, 1);
      expect(
        (await fineRepo.getById('f1'))!.syncStatus,
        SyncStatus.synced,
      );
    });

    test('propaga soft-delete', () async {
      await fineRepo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 25, 11);
      await fineRepo.softDelete('f1');
      await sync.sync('u1');
      expect(remote.store['f1']!.deletedAt, isNotNull);
      final raw = await (db.select(
        db.fines,
      )..where((t) => t.id.equals('f1'))).getSingle();
      expect(raw.syncStatus, SyncStatus.synced);
    });

    test('falha parcial não afeta outros', () async {
      await fineRepo.create(sample(id: 'f1'));
      await fineRepo.create(sample(id: 'f2'));
      await fineRepo.create(sample(id: 'f3'));
      remote.failUpsertForIds = {'f2'};
      final r = await sync.sync('u1');
      expect(r.pushed, 2);
      expect(r.pushFailures, 1);
      expect(
        (await fineRepo.getById('f2'))!.syncStatus,
        SyncStatus.pending,
      );
    });
  });

  group('pull', () {
    test('insere novo como synced', () async {
      remote.seed(sample(id: 'f1', updatedAt: fakeNow));
      final r = await sync.sync('u1');
      expect(
        (await fineRepo.getById('f1'))!.syncStatus,
        SyncStatus.synced,
      );
      expect(r.pulled, 1);
    });

    test('cursor incremental', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 11);
      remote.seed(sample(id: 'f1', updatedAt: t1));
      await sync.sync('u1');
      expect(remote.lastFetchSince, isNull);
      remote.seed(sample(id: 'f2', updatedAt: t2));
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
        id: 'f1',
        description: 'Antigo',
        updatedAt: t1,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'f1', description: 'Novo', updatedAt: t2));
      final r = await sync.sync('u1');
      expect((await fineRepo.getById('f1'))!.description, 'Novo');
      expect(r.pulled, 1);
    });

    test('local mais novo preservado (guard LWW)', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);
      await facade.upsertFromRemote(sample(
        id: 'f1',
        description: 'LocalNovo',
        updatedAt: t2,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'f1', description: 'RemotoAntigo', updatedAt: t1));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await fineRepo.getById('f1'))!.description, 'LocalNovo');
      expect(r.pulled, 0);
    });

    test('empate updated_at: local vence', () async {
      final t = DateTime.utc(2026, 5, 25, 10);
      await facade.upsertFromRemote(sample(
        id: 'f1',
        description: 'Local',
        updatedAt: t,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'f1', description: 'Remoto', updatedAt: t));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await fineRepo.getById('f1'))!.description, 'Local');
      expect(r.pulled, 0);
    });
  });

  group('isolamento por user via JOIN com vehicles', () {
    test('fine de outro user NÃO aparece em listPending(u1)', () async {
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
      await fineRepo.create(sample(id: 'f_u1', vehicleId: 'v1'));
      await fineRepo.create(sample(id: 'f_u2', vehicleId: 'v2'));

      expect((await facade.listPending('u1')).map((f) => f.id), ['f_u1']);
      expect((await facade.listPending('u2')).map((f) => f.id), ['f_u2']);
    });
  });

  group('erros', () {
    test('falha pull não vaza, push prévio preservado', () async {
      await fineRepo.create(sample());
      remote.throwOnFetch = true;
      final r = await sync.sync('u1');
      expect(r.pushed, 1);
      expect(r.pulled, 0);
      expect(r.pullError, isNotNull);
      expect(
        (await fineRepo.getById('f1'))!.syncStatus,
        SyncStatus.synced,
      );
    });
  });
}
