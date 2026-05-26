import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/data/sync/remote_vehicle_source.dart';
import 'package:autolog/data/sync/vehicle_sync_facade.dart';
import 'package:autolog/data/sync/vehicle_sync_service.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/vehicle_repository.dart' as domain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 1.2 — VehicleSyncService (push pending + pull incremental + LWW).
/// Spec: docs/specs/sprint-1.2-sync-service.md

/// Fake em memória que simula o RemoteVehicleSource (sem rede).
class FakeRemoteVehicleSource implements RemoteVehicleSource {
  final Map<String, Vehicle> store = {};

  // Capturas pra asserts.
  DateTime? lastFetchSince;
  String? lastFetchUserId;
  int fetchCallCount = 0;

  // Knobs.
  Set<String> failUpsertForIds = {};
  bool throwOnFetch = false;
  bool ignoreSince = false; // pra testar o guard de LWW sem o cursor "proteger"

  void seed(Vehicle v) => store[v.id] = v;

  @override
  Future<void> upsert(Vehicle vehicle) async {
    if (failUpsertForIds.contains(vehicle.id)) {
      throw Exception('fake upsert failure for ${vehicle.id}');
    }
    store[vehicle.id] = vehicle;
  }

  @override
  Future<List<Vehicle>> fetchUpdatedSince({
    required String userId,
    required DateTime? since,
  }) async {
    fetchCallCount++;
    lastFetchUserId = userId;
    lastFetchSince = since;
    if (throwOnFetch) {
      throw Exception('fake fetch failure');
    }
    final ofUser = store.values.where((v) => v.userId == userId);
    final filtered = (since == null || ignoreSince)
        ? ofUser
        : ofUser.where((v) => v.updatedAt.isAfter(since));
    final list = filtered.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return list;
  }
}

void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.VehicleRepository repo;
  late VehicleSyncFacade facade;
  late FakeRemoteVehicleSource remote;
  late VehicleSyncService sync;

  DateTime now() => fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 23, 10);
    repo = DriftVehicleRepository(db, now: now);
    facade = DriftVehicleSyncFacade(db);
    remote = FakeRemoteVehicleSource();
    sync = VehicleSyncService(facade: facade, remote: remote);
  });

  tearDown(() => db.close());

  Vehicle sampleVehicle({
    String id = 'v1',
    String userId = 'u1',
    String nickname = 'Meu Civic',
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus syncStatus = SyncStatus.pending,
    DateTime? deletedAt,
  }) {
    final base = createdAt ?? fakeNow;
    return Vehicle(
      id: id,
      userId: userId,
      nickname: nickname,
      fuelType: FuelType.flex,
      initialOdometer: 45000,
      createdAt: base,
      updatedAt: updatedAt ?? base,
      syncStatus: syncStatus,
      deletedAt: deletedAt,
    );
  }

  group('push', () {
    test('envia pending, marca synced, conta corretamente', () async {
      await repo.create(sampleVehicle()); // pending

      final result = await sync.sync('u1');

      expect(remote.store['v1'], isNotNull);
      expect(remote.store['v1']!.nickname, 'Meu Civic');

      final local = await repo.getById('v1');
      expect(local!.syncStatus, SyncStatus.synced);
      expect(result.pushed, 1);
      expect(result.pushFailures, 0);
    });

    test('propaga soft-delete (envia row com deletedAt != null)', () async {
      await repo.create(sampleVehicle());
      fakeNow = DateTime.utc(2026, 5, 23, 11);
      await repo.softDelete('v1');

      await sync.sync('u1');

      expect(remote.store['v1']!.deletedAt, isNotNull);
      // Local continua deletado, mas agora synced.
      final raw = await (db.select(
        db.vehicles,
      )..where((t) => t.id.equals('v1'))).getSingle();
      expect(raw.deletedAt, isNotNull);
      expect(raw.syncStatus, SyncStatus.synced);
    });

    test('falha parcial — uns sobem, outros continuam pending', () async {
      await repo.create(sampleVehicle(id: 'v1'));
      await repo.create(sampleVehicle(id: 'v2'));
      await repo.create(sampleVehicle(id: 'v3'));

      remote.failUpsertForIds = {'v2'};

      final result = await sync.sync('u1');

      expect(result.pushed, 2);
      expect(result.pushFailures, 1);
      expect((await repo.getById('v1'))!.syncStatus, SyncStatus.synced);
      expect((await repo.getById('v2'))!.syncStatus, SyncStatus.pending);
      expect((await repo.getById('v3'))!.syncStatus, SyncStatus.synced);
    });
  });

  group('pull', () {
    test('insere row novo do remoto como synced', () async {
      remote.seed(sampleVehicle(id: 'v1', updatedAt: fakeNow));

      final result = await sync.sync('u1');

      final local = await repo.getById('v1');
      expect(local, isNotNull);
      expect(local!.syncStatus, SyncStatus.synced);
      expect(result.pulled, 1);
    });

    test('cursor incremental — segundo sync só pega o que é novo', () async {
      final t1 = DateTime.utc(2026, 5, 23, 10);
      final t2 = DateTime.utc(2026, 5, 23, 11);

      remote.seed(sampleVehicle(id: 'v1', updatedAt: t1));
      final r1 = await sync.sync('u1');
      expect(r1.pulled, 1);
      expect(remote.lastFetchSince, isNull); // primeira vez, cursor null

      // Agora chega v2 mais novo.
      remote.seed(sampleVehicle(id: 'v2', updatedAt: t2));
      final r2 = await sync.sync('u1');

      expect(remote.lastFetchSince, t1); // cursor avançou pra t1
      expect(r2.pulled, 1); // só v2 entra
      expect(await repo.getById('v2'), isNotNull);
    });

    test('cursor inicial null quando não há nada synced', () async {
      await sync.sync('u1'); // nada local, nada remoto
      expect(remote.lastFetchSince, isNull);
    });

    test('isolamento — fetch é chamado com o userId correto', () async {
      await sync.sync('u-especifico');
      expect(remote.lastFetchUserId, 'u-especifico');
    });
  });

  group('conflito (last-write-wins por updated_at)', () {
    test('remoto mais novo sobrescreve local', () async {
      final t1 = DateTime.utc(2026, 5, 23, 10);
      final t2 = DateTime.utc(2026, 5, 23, 12);

      // Local synced em T1 com nickname antigo.
      await facade.upsertFromRemote(
        sampleVehicle(
          id: 'v1',
          nickname: 'antigo',
          createdAt: t1,
          updatedAt: t1,
          syncStatus: SyncStatus.synced,
        ),
      );

      // Remoto tem v1 em T2 com nickname novo.
      remote.seed(
        sampleVehicle(id: 'v1', nickname: 'novo', createdAt: t1, updatedAt: t2),
      );

      final result = await sync.sync('u1');

      final local = await repo.getById('v1');
      expect(local!.nickname, 'novo');
      expect(local.updatedAt, t2);
      expect(local.syncStatus, SyncStatus.synced);
      expect(result.pulled, 1);
    });

    test('local mais novo é preservado (guard do LWW)', () async {
      final t1 = DateTime.utc(2026, 5, 23, 10);
      final t2 = DateTime.utc(2026, 5, 23, 12);

      // Local synced em T2 (mais novo) — força ignoreSince pra testar o guard
      // sem o cursor proteger.
      await facade.upsertFromRemote(
        sampleVehicle(
          id: 'v1',
          nickname: 'local-novo',
          createdAt: t1,
          updatedAt: t2,
          syncStatus: SyncStatus.synced,
        ),
      );

      // Remoto retorna v1@T1 (mais velho).
      remote.seed(
        sampleVehicle(
          id: 'v1',
          nickname: 'remoto-velho',
          createdAt: t1,
          updatedAt: t1,
        ),
      );
      remote.ignoreSince = true; // bypassa cursor pra forçar a entrega

      final result = await sync.sync('u1');

      final local = await repo.getById('v1');
      expect(local!.nickname, 'local-novo'); // não foi sobrescrito
      expect(local.updatedAt, t2);
      expect(result.pulled, 0);
    });

    test(
      'empate de updated_at — local vence (não sobrescreve à toa)',
      () async {
        final t1 = DateTime.utc(2026, 5, 23, 10);

        await facade.upsertFromRemote(
          sampleVehicle(
            id: 'v1',
            nickname: 'local',
            createdAt: t1,
            updatedAt: t1,
            syncStatus: SyncStatus.synced,
          ),
        );
        remote.seed(
          sampleVehicle(
            id: 'v1',
            nickname: 'remoto',
            createdAt: t1,
            updatedAt: t1,
          ),
        );
        remote.ignoreSince = true;

        final result = await sync.sync('u1');

        final local = await repo.getById('v1');
        expect(local!.nickname, 'local');
        expect(result.pulled, 0);
      },
    );
  });

  group('erros', () {
    test('falha de pull não vaza exception e não afeta push', () async {
      await repo.create(sampleVehicle(id: 'v1')); // pending
      remote.throwOnFetch = true;

      final result = await sync.sync('u1');

      expect(result.pushed, 1); // push aconteceu antes do fetch falhar
      expect(result.pulled, 0);
      expect(result.pullError, isNotNull);
      expect((await repo.getById('v1'))!.syncStatus, SyncStatus.synced);
    });
  });
}
