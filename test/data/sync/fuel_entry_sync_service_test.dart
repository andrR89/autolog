import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/data/sync/fuel_entry_sync_facade.dart';
import 'package:autolog/data/sync/fuel_entry_sync_service.dart';
import 'package:autolog/data/sync/remote_fuel_entry_source.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart'
    as fdomain;
import 'package:autolog/domain/repositories/vehicle_repository.dart'
    as vdomain;
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.D-fuel — FuelEntrySyncService (mirror de 1.2 pra fuel_entries).
/// Spec: docs/specs/sprint-6.D-fuel-sync.md

/// Fake remote pra fuel_entries (mirror do FakeRemoteVehicleSource).
class FakeRemoteFuelEntrySource implements RemoteFuelEntrySource {
  final Map<String, FuelEntry> store = {};
  DateTime? lastFetchSince;
  String? lastFetchUserId;
  int fetchCallCount = 0;
  Set<String> failUpsertForIds = {};
  bool throwOnFetch = false;
  bool ignoreSince = false;

  void seed(FuelEntry e) => store[e.id] = e;

  @override
  Future<void> upsert(FuelEntry entry) async {
    if (failUpsertForIds.contains(entry.id)) {
      throw Exception('fake upsert failure for ${entry.id}');
    }
    store[entry.id] = entry;
  }

  @override
  Future<List<FuelEntry>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    fetchCallCount++;
    lastFetchUserId = userId;
    lastFetchSince = since;
    if (throwOnFetch) throw Exception('fake fetch failure');
    final filtered = (since == null || ignoreSince)
        ? store.values
        : store.values.where((e) => e.updatedAt.isAfter(since));
    final list = filtered.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return list;
  }
}

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late vdomain.VehicleRepository vehicleRepo;
  late fdomain.FuelEntryRepository fuelRepo;
  late FuelEntrySyncFacade facade;
  late FakeRemoteFuelEntrySource remote;
  late FuelEntrySyncService sync;

  DateTime now() => fakeNow;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 25, 10);
    vehicleRepo = DriftVehicleRepository(db, now: now);
    fuelRepo = DriftFuelEntryRepository(db, now: now);
    facade = DriftFuelEntrySyncFacade(db);
    remote = FakeRemoteFuelEntrySource();
    sync = FuelEntrySyncService(facade: facade, remote: remote);

    // Cria veículo padrão pro user 'u1' — fuel_entries dependem de vehicle.
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

  FuelEntry sample({
    String id = 'f1',
    String vehicleId = 'v1',
    DateTime? date,
    DateTime? updatedAt,
    int odometer = 11000,
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? deletedAt,
  }) {
    final d = date ?? fakeNow;
    return FuelEntry(
      id: id,
      vehicleId: vehicleId,
      date: d,
      odometer: odometer,
      liters: Decimal.parse('40'),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse('200'),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: d,
      updatedAt: updatedAt ?? d,
      syncStatus: syncStatus,
      deletedAt: deletedAt,
    );
  }

  group('push', () {
    test('envia pending, marca synced, conta certo', () async {
      await fuelRepo.create(sample());

      final result = await sync.sync('u1');

      expect(remote.store['f1'], isNotNull);
      expect(result.pushed, 1);
      expect(result.pushFailures, 0);

      final local = await fuelRepo.getById('f1');
      expect(local!.syncStatus, SyncStatus.synced);
    });

    test('propaga soft-delete (envia com deletedAt != null)', () async {
      await fuelRepo.create(sample());
      fakeNow = DateTime.utc(2026, 5, 25, 11);
      await fuelRepo.softDelete('f1');

      await sync.sync('u1');

      expect(remote.store['f1']!.deletedAt, isNotNull);
      final raw = await (db.select(
        db.fuelEntries,
      )..where((t) => t.id.equals('f1'))).getSingle();
      expect(raw.deletedAt, isNotNull);
      expect(raw.syncStatus, SyncStatus.synced);
    });

    test('falha parcial — 1 falha, 2 sobem', () async {
      await fuelRepo.create(sample(id: 'f1', odometer: 11000));
      await fuelRepo.create(sample(id: 'f2', odometer: 11100));
      await fuelRepo.create(sample(id: 'f3', odometer: 11200));

      remote.failUpsertForIds = {'f2'};

      final result = await sync.sync('u1');

      expect(result.pushed, 2);
      expect(result.pushFailures, 1);
      expect((await fuelRepo.getById('f1'))!.syncStatus, SyncStatus.synced);
      expect((await fuelRepo.getById('f2'))!.syncStatus, SyncStatus.pending);
      expect((await fuelRepo.getById('f3'))!.syncStatus, SyncStatus.synced);
    });
  });

  group('pull', () {
    test('insere novo do remoto como synced', () async {
      remote.seed(sample(id: 'f1', updatedAt: fakeNow));
      final r = await sync.sync('u1');
      final local = await fuelRepo.getById('f1');
      expect(local, isNotNull);
      expect(local!.syncStatus, SyncStatus.synced);
      expect(r.pulled, 1);
    });

    test('cursor incremental: segundo sync usa max anterior', () async {
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

  group('conflito (LWW por updated_at)', () {
    test('remoto mais novo sobrescreve local', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);

      await facade.upsertFromRemote(sample(
        id: 'f1',
        odometer: 12000,
        updatedAt: t1,
        syncStatus: SyncStatus.synced,
      ));

      remote.seed(sample(
        id: 'f1',
        odometer: 13000,
        updatedAt: t2,
      ));

      final r = await sync.sync('u1');
      final local = await fuelRepo.getById('f1');
      expect(local!.odometer, 13000);
      expect(local.updatedAt, t2);
      expect(r.pulled, 1);
    });

    test('local mais novo é preservado (guard LWW)', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);
      final t2 = DateTime.utc(2026, 5, 25, 12);

      await facade.upsertFromRemote(sample(
        id: 'f1',
        odometer: 14000,
        updatedAt: t2,
        syncStatus: SyncStatus.synced,
      ));

      remote.seed(sample(
        id: 'f1',
        odometer: 13000,
        updatedAt: t1,
      ));
      remote.ignoreSince = true;

      final r = await sync.sync('u1');
      final local = await fuelRepo.getById('f1');
      expect(local!.odometer, 14000);
      expect(r.pulled, 0);
    });

    test('empate updated_at: local vence', () async {
      final t1 = DateTime.utc(2026, 5, 25, 10);

      await facade.upsertFromRemote(sample(
        id: 'f1',
        odometer: 12000,
        updatedAt: t1,
        syncStatus: SyncStatus.synced,
      ));
      remote.seed(sample(
        id: 'f1',
        odometer: 13000,
        updatedAt: t1,
      ));
      remote.ignoreSince = true;

      final r = await sync.sync('u1');
      final local = await fuelRepo.getById('f1');
      expect(local!.odometer, 12000);
      expect(r.pulled, 0);
    });
  });

  group('isolamento por user via JOIN com vehicles', () {
    test('fuel de veículo de outro user NÃO aparece em listPending(u1)',
        () async {
      // Cria outro vehicle pra user u2.
      await vehicleRepo.create(Vehicle(
        id: 'v2',
        userId: 'u2',
        nickname: 'Outro',
        fuelType: FuelType.gasolina,
        initialOdometer: 20000,
        createdAt: DateTime.utc(2000),
        updatedAt: DateTime.utc(2000),
        syncStatus: SyncStatus.synced,
      ));

      // Cria fuel pra cada user.
      await fuelRepo.create(sample(id: 'f_u1', vehicleId: 'v1'));
      await fuelRepo.create(sample(id: 'f_u2', vehicleId: 'v2'));

      final pendingU1 = await facade.listPending('u1');
      expect(pendingU1.map((e) => e.id), ['f_u1']);

      final pendingU2 = await facade.listPending('u2');
      expect(pendingU2.map((e) => e.id), ['f_u2']);
    });
  });

  group('erros', () {
    test('falha de pull não vaza, não afeta push', () async {
      await fuelRepo.create(sample());
      remote.throwOnFetch = true;

      final r = await sync.sync('u1');

      expect(r.pushed, 1);
      expect(r.pulled, 0);
      expect(r.pullError, isNotNull);
      expect((await fuelRepo.getById('f1'))!.syncStatus, SyncStatus.synced);
    });
  });
}
