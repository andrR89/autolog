import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/fine_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/repositories/fine_repository.dart' as domain;
import 'package:autolog/domain/repositories/vehicle_repository.dart' as vdomain;
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — Repositório de multas (CRUD local + soft delete).
void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.FineRepository repo;
  late vdomain.VehicleRepository vehicleRepo;

  DateTime now() => fakeNow;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 24, 10);
    repo = DriftFineRepository(db, now: now);
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

  Fine sample({
    String id = 'f1',
    String vehicleId = 'v1',
    String? autoNumber,
    String description = 'Excesso de velocidade',
    Decimal? amount,
    DateTime? dueDate,
    bool paid = false,
    int? points = 5,
    SyncStatus syncStatus = SyncStatus.pending,
  }) {
    return Fine(
      id: id,
      vehicleId: vehicleId,
      autoNumber: autoNumber,
      issuedAt: DateTime.utc(2026, 5, 1),
      description: description,
      amount: amount ?? Decimal.parse('293.47'),
      dueDate: dueDate,
      paid: paid,
      points: points,
      createdAt: DateTime.utc(2000),
      updatedAt: DateTime.utc(2000),
      syncStatus: syncStatus,
    );
  }

  group('create', () {
    test('insere, marca pending, define timestamps', () async {
      await repo.create(sample());

      final saved = await repo.getById('f1');
      expect(saved, isNotNull);
      expect(saved!.id, 'f1');
      expect(saved.syncStatus, SyncStatus.pending);
      expect(saved.createdAt, fakeNow);
      expect(saved.updatedAt, fakeNow);
      expect(saved.deletedAt, isNull);
    });

    test('caller mandando synced é sobrescrito para pending', () async {
      await repo.create(sample(syncStatus: SyncStatus.synced));
      final saved = await repo.getById('f1');
      expect(saved!.syncStatus, SyncStatus.pending);
    });

    test('preserva campos opcionais null', () async {
      await repo.create(sample(autoNumber: null, points: null, dueDate: null));
      final saved = await repo.getById('f1');
      expect(saved!.autoNumber, isNull);
      expect(saved.points, isNull);
      expect(saved.dueDate, isNull);
    });
  });

  group('listByVehicle', () {
    test('retorna multas não deletadas, ordenadas por issuedAt DESC', () async {
      await repo.create(sample(id: 'f1'));
      await repo.create(sample(id: 'f2', description: 'Outra'));
      final list = await repo.listByVehicle('v1');
      expect(list.length, 2);
      expect(list.map((f) => f.id), containsAll(['f1', 'f2']));
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
      await repo.create(sample(id: 'f1', vehicleId: 'v1'));
      await repo.create(sample(id: 'f2', vehicleId: 'v2'));

      final list1 = await repo.listByVehicle('v1');
      final list2 = await repo.listByVehicle('v2');
      expect(list1.map((f) => f.id), ['f1']);
      expect(list2.map((f) => f.id), ['f2']);
    });

    test('não retorna soft-deletados', () async {
      await repo.create(sample(id: 'f1'));
      await repo.softDelete('f1');
      final list = await repo.listByVehicle('v1');
      expect(list, isEmpty);
    });
  });

  group('watchUnpaid', () {
    test('emite apenas multas não pagas', () async {
      await repo.create(sample(id: 'f1', paid: false));
      await repo.create(sample(id: 'f2', paid: false));

      final stream = repo.watchUnpaid('v1');
      final first = await stream.first;
      expect(first.length, 2);

      // Marca f1 como pago
      await repo.togglePaid('f1');
      final second = await stream.first;
      expect(second.length, 1);
      expect(second.first.id, 'f2');
    });
  });

  group('togglePaid', () {
    test('flipa paid false → true e marca pending', () async {
      await repo.create(sample(id: 'f1', paid: false));
      await repo.togglePaid('f1');

      final f = await repo.getById('f1');
      expect(f!.paid, true);
      expect(f.syncStatus, SyncStatus.pending);
    });

    test('flipa paid true → false', () async {
      await repo.create(sample(id: 'f1', paid: false));
      await repo.togglePaid('f1');
      await repo.togglePaid('f1');

      final f = await repo.getById('f1');
      expect(f!.paid, false);
    });

    test('não faz nada se não existir', () async {
      await expectLater(repo.togglePaid('fantasma'), completes);
    });
  });

  group('softDelete', () {
    test('marca deleted_at e esconde dos reads', () async {
      await repo.create(sample(id: 'f1'));
      fakeNow = DateTime.utc(2026, 5, 24, 12);
      await repo.softDelete('f1');
      expect(await repo.getById('f1'), isNull);
      expect(await repo.listByVehicle('v1'), isEmpty);
    });

    test('é idempotente', () async {
      await repo.create(sample(id: 'f1'));
      fakeNow = DateTime.utc(2026, 5, 24, 12);
      await repo.softDelete('f1');

      final rawFirst = await (db.select(
        db.fines,
      )..where((t) => t.id.equals('f1'))).getSingle();
      final firstDeletedAt = rawFirst.deletedAt;

      fakeNow = DateTime.utc(2026, 5, 24, 13);
      await repo.softDelete('f1');

      final rawSecond = await (db.select(
        db.fines,
      )..where((t) => t.id.equals('f1'))).getSingle();
      expect(rawSecond.deletedAt, firstDeletedAt);
    });

    test('não faz nada se não existir', () async {
      await expectLater(repo.softDelete('fantasma'), completes);
    });
  });
}
