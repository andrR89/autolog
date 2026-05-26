import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/insurance_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/insurance_repository.dart' as domain;
import 'package:autolog/domain/repositories/vehicle_repository.dart' as vdomain;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — Repositório de apólices de seguro (CRUD local + soft delete).
void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.InsuranceRepository repo;
  late vdomain.VehicleRepository vehicleRepo;

  DateTime now() => fakeNow;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 24, 10);
    repo = DriftInsuranceRepository(db, now: now);
    vehicleRepo = DriftVehicleRepository(db, now: now);

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
    String? policyNumber = 'POL-001',
    DateTime? startsAt,
    DateTime? endsAt,
    SyncStatus syncStatus = SyncStatus.pending,
  }) {
    return Insurance(
      id: id,
      vehicleId: vehicleId,
      insurer: insurer,
      policyNumber: policyNumber,
      startsAt: startsAt ?? DateTime.utc(2026, 1, 1),
      endsAt: endsAt ?? DateTime.utc(2027, 1, 1),
      premiumPaid: null,
      notes: null,
      createdAt: DateTime.utc(2000),
      updatedAt: DateTime.utc(2000),
      syncStatus: syncStatus,
    );
  }

  group('create', () {
    test('insere, marca pending, define timestamps', () async {
      await repo.create(sample());

      final saved = await repo.getById('i1');
      expect(saved, isNotNull);
      expect(saved!.id, 'i1');
      expect(saved.syncStatus, SyncStatus.pending);
      expect(saved.createdAt, fakeNow);
      expect(saved.updatedAt, fakeNow);
      expect(saved.deletedAt, isNull);
    });

    test('caller mandando synced é sobrescrito para pending', () async {
      await repo.create(sample(syncStatus: SyncStatus.synced));
      final saved = await repo.getById('i1');
      expect(saved!.syncStatus, SyncStatus.pending);
    });
  });

  group('listByVehicle', () {
    test('retorna apólices não deletadas', () async {
      await repo.create(sample(id: 'i1'));
      await repo.create(sample(id: 'i2', policyNumber: 'POL-002'));
      final list = await repo.listByVehicle('v1');
      expect(list.length, 2);
    });

    test('isolamento por vehicleId', () async {
      await vehicleRepo.create(Vehicle(
        id: 'v2',
        userId: 'u2',
        nickname: 'Otro',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2000),
        updatedAt: DateTime.utc(2000),
        syncStatus: SyncStatus.synced,
      ));
      await repo.create(sample(id: 'i1', vehicleId: 'v1'));
      await repo.create(sample(id: 'i2', vehicleId: 'v2'));

      final list1 = await repo.listByVehicle('v1');
      final list2 = await repo.listByVehicle('v2');
      expect(list1.map((i) => i.id), ['i1']);
      expect(list2.map((i) => i.id), ['i2']);
    });

    test('não retorna soft-deletados', () async {
      await repo.create(sample(id: 'i1'));
      await repo.softDelete('i1');
      final list = await repo.listByVehicle('v1');
      expect(list, isEmpty);
    });
  });

  group('watchActive', () {
    test('emite apenas apólices com endsAt > now', () async {
      final futureEnd = DateTime.utc(2028, 1, 1);
      final pastEnd = DateTime.utc(2025, 1, 1);

      await repo.create(sample(id: 'i_ativa', endsAt: futureEnd));
      await repo.create(sample(id: 'i_expirada', endsAt: pastEnd));

      final ref = DateTime.utc(2026, 6, 1);
      final stream = repo.watchActive('v1', ref);
      final list = await stream.first;

      expect(list.map((i) => i.id), ['i_ativa']);
    });

    test('excluídas não aparecem mesmo que ativas', () async {
      final futureEnd = DateTime.utc(2028, 1, 1);
      await repo.create(sample(id: 'i1', endsAt: futureEnd));
      await repo.softDelete('i1');

      final ref = DateTime.utc(2026, 6, 1);
      final stream = repo.watchActive('v1', ref);
      final list = await stream.first;
      expect(list, isEmpty);
    });
  });

  group('softDelete', () {
    test('marca deleted_at e esconde dos reads', () async {
      await repo.create(sample(id: 'i1'));
      fakeNow = DateTime.utc(2026, 5, 24, 12);
      await repo.softDelete('i1');
      expect(await repo.getById('i1'), isNull);
      expect(await repo.listByVehicle('v1'), isEmpty);
    });

    test('é idempotente', () async {
      await repo.create(sample(id: 'i1'));
      fakeNow = DateTime.utc(2026, 5, 24, 12);
      await repo.softDelete('i1');

      final rawFirst = await (db.select(
        db.insurances,
      )..where((t) => t.id.equals('i1'))).getSingle();
      final firstDeletedAt = rawFirst.deletedAt;

      fakeNow = DateTime.utc(2026, 5, 24, 13);
      await repo.softDelete('i1');

      final rawSecond = await (db.select(
        db.insurances,
      )..where((t) => t.id.equals('i1'))).getSingle();
      expect(rawSecond.deletedAt, firstDeletedAt);
    });

    test('não faz nada se não existir', () async {
      await expectLater(repo.softDelete('fantasma'), completes);
    });
  });
}
