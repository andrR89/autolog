import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/insurance_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/data/sync/insurance_sync_facade.dart';
import 'package:autolog/data/sync/insurance_sync_service.dart';
import 'package:autolog/data/sync/remote_insurance_source.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/insurance_repository.dart' as idomain;
import 'package:autolog/domain/repositories/vehicle_repository.dart' as vdomain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — InsuranceSyncService (mirror de reminder_sync_service_test).

class FakeRemoteInsuranceSource implements RemoteInsuranceSource {
  final Map<String, Insurance> store = {};
  DateTime? lastFetchSince;
  int fetchCallCount = 0;
  Set<String> failUpsertForIds = {};
  bool throwOnFetch = false;
  bool ignoreSince = false;

  void seed(Insurance i) => store[i.id] = i;

  @override
  Future<void> upsert(Insurance insurance) async {
    if (failUpsertForIds.contains(insurance.id)) {
      throw Exception('fake upsert failure for ${insurance.id}');
    }
    store[insurance.id] = insurance;
  }

  @override
  Future<List<Insurance>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    fetchCallCount++;
    lastFetchSince = since;
    if (throwOnFetch) throw Exception('fake fetch failure');
    final filtered = (since == null || ignoreSince)
        ? store.values
        : store.values.where((i) => i.updatedAt.isAfter(since));
    final list = filtered.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return list;
  }
}

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late vdomain.VehicleRepository vehicleRepo;
  late idomain.InsuranceRepository insuranceRepo;
  late InsuranceSyncFacade facade;
  late FakeRemoteInsuranceSource remote;
  late InsuranceSyncService sync;

  DateTime now() => fakeNow;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 25, 10);
    vehicleRepo = DriftVehicleRepository(db, now: now);
    insuranceRepo = DriftInsuranceRepository(db, now: now);
    facade = DriftInsuranceSyncFacade(db);
    remote = FakeRemoteInsuranceSource();
    sync = InsuranceSyncService(facade: facade, remote: remote);

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

  Insurance sample({
    String id = 'i1',
    String vehicleId = 'v1',
    String? insurer = 'Porto Seguro',
    DateTime? updatedAt,
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? deletedAt,
  }) {
    final d = fakeNow;
    return Insurance(
      id: id,
      vehicleId: vehicleId,
      insurer: insurer,
      policyNumber: null,
      startsAt: DateTime.utc(2026, 1, 1),
      endsAt: DateTime.utc(2027, 1, 1),
      premiumPaid: null,
      notes: null,
      createdAt: d,
      updatedAt: updatedAt ?? d,
      syncStatus: syncStatus,
      deletedAt: deletedAt,
    );
  }

  group('push', () {
    test('envia pending, marca synced', () async {
      await insuranceRepo.create(sample());
      final r = await sync.sync('u1');
      expect(remote.store['i1'], isNotNull);
      expect(r.pushed, 1);
      expect(
        (await insuranceRepo.getById('i1'))!.syncStatus,
        SyncStatus.synced,
      );
    });

    test('propaga soft-delete', () async {
      await insuranceRepo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 25, 11);
      await insuranceRepo.softDelete('i1');
      await sync.sync('u1');
      expect(remote.store['i1']!.deletedAt, isNotNull);
      final raw = await (db.select(
        db.insurances,
      )..where((t) => t.id.equals('i1'))).getSingle();
      expect(raw.syncStatus, SyncStatus.synced);
    });

    test('falha parcial não afeta outros', () async {
      await insuranceRepo.create(sample(id: 'i1'));
      await insuranceRepo.create(sample(id: 'i2'));
      await insuranceRepo.create(sample(id: 'i3'));
      remote.failUpsertForIds = {'i2'};
      final r = await sync.sync('u1');
      expect(r.pushed, 2);
      expect(r.pushFailures, 1);
      expect(
        (await insuranceRepo.getById('i2'))!.syncStatus,
        SyncStatus.pending,
      );
    });
  });

  group('pull', () {
    test('insere novo como synced', () async {
      remote.seed(sample(id: 'i1', updatedAt: fakeNow));
      final r = await sync.sync('u1');
      expect(
        (await insuranceRepo.getById('i1'))!.syncStatus,
        SyncStatus.synced,
      );
      expect(r.pulled, 1);
    });

    test('cursor incremental', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 11);
      remote.seed(sample(id: 'i1', updatedAt: t1));
      await sync.sync('u1');
      expect(remote.lastFetchSince, isNull);
      remote.seed(sample(id: 'i2', updatedAt: t2));
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
        id: 'i1',
        insurer: 'Antiga',
        updatedAt: t1,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'i1', insurer: 'Nova', updatedAt: t2));
      final r = await sync.sync('u1');
      expect((await insuranceRepo.getById('i1'))!.insurer, 'Nova');
      expect(r.pulled, 1);
    });

    test('local mais novo preservado (guard LWW)', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);
      await facade.upsertFromRemote(sample(
        id: 'i1',
        insurer: 'LocalNovo',
        updatedAt: t2,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'i1', insurer: 'RemotoAntigo', updatedAt: t1));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await insuranceRepo.getById('i1'))!.insurer, 'LocalNovo');
      expect(r.pulled, 0);
    });

    test('empate updated_at: local vence', () async {
      final t = DateTime.utc(2026, 5, 25, 10);
      await facade.upsertFromRemote(sample(
        id: 'i1',
        insurer: 'Local',
        updatedAt: t,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(id: 'i1', insurer: 'Remoto', updatedAt: t));
      remote.ignoreSince = true;
      final r = await sync.sync('u1');
      expect((await insuranceRepo.getById('i1'))!.insurer, 'Local');
      expect(r.pulled, 0);
    });
  });

  group('isolamento por user via JOIN com vehicles', () {
    test('insurance de outro user NÃO aparece em listPending(u1)', () async {
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
      await insuranceRepo.create(sample(id: 'i_u1', vehicleId: 'v1'));
      await insuranceRepo.create(sample(id: 'i_u2', vehicleId: 'v2'));

      expect((await facade.listPending('u1')).map((i) => i.id), ['i_u1']);
      expect((await facade.listPending('u2')).map((i) => i.id), ['i_u2']);
    });
  });

  group('erros', () {
    test('falha pull não vaza, push prévio preservado', () async {
      await insuranceRepo.create(sample());
      remote.throwOnFetch = true;
      final r = await sync.sync('u1');
      expect(r.pushed, 1);
      expect(r.pulled, 0);
      expect(r.pullError, isNotNull);
      expect(
        (await insuranceRepo.getById('i1'))!.syncStatus,
        SyncStatus.synced,
      );
    });
  });
}
