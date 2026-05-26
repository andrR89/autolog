import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/repositories/fuel_entry_repository.dart'
    as domain;
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 2.1 — Repositório de fuel_entries (CRUD local + soft delete).
/// Spec: docs/specs/sprint-2.1-fuel-entry-repository.md
void main() {
  late AppDatabase db;
  late DateTime fakeNow;
  late domain.FuelEntryRepository repo;

  DateTime now() => fakeNow;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeNow = DateTime.utc(2026, 5, 23, 10);
    repo = DriftFuelEntryRepository(db, now: now);
  });

  tearDown(() => db.close());

  FuelEntry sample({
    String id = 'f1',
    String vehicleId = 'v1',
    DateTime? date,
    int odometer = 45100,
    Decimal? liters,
    Decimal? pricePerLiter,
    Decimal? totalCost,
    bool fullTank = true,
    FuelType fuelType = FuelType.gasolina,
    FuelSource source = FuelSource.manual,
    SyncStatus syncStatus = SyncStatus.synced, // será sobrescrito pelo repo
  }) {
    return FuelEntry(
      id: id,
      vehicleId: vehicleId,
      date: date ?? fakeNow,
      odometer: odometer,
      liters: liters ?? Decimal.parse('40'),
      pricePerLiter: pricePerLiter ?? Decimal.parse('5'),
      totalCost: totalCost ?? Decimal.parse('200'),
      fullTank: fullTank,
      fuelType: fuelType,
      source: source,
      // createdAt/updatedAt ignorados pelo repo no create.
      createdAt: DateTime.utc(2000),
      updatedAt: DateTime.utc(2000),
      syncStatus: syncStatus,
    );
  }

  group('create', () {
    test('insere, marca pending, define timestamps', () async {
      final saved = await repo.create(sample());

      expect(saved.id, 'f1');
      expect(saved.vehicleId, 'v1');
      expect(saved.syncStatus, SyncStatus.pending);
      expect(saved.createdAt, fakeNow);
      expect(saved.updatedAt, fakeNow);
      expect(saved.deletedAt, isNull);

      final got = await repo.getById('f1');
      expect(got, saved);
    });

    test('precisão decimal SAGRADA — roundtrip exato sem double', () async {
      final liters = Decimal.parse('43.219');
      final price = Decimal.parse('5.799');
      final total = Decimal.parse('250.634781');

      final saved = await repo.create(
        sample(liters: liters, pricePerLiter: price, totalCost: total),
      );

      expect(saved.liters, liters);
      expect(saved.pricePerLiter, price);
      expect(saved.totalCost, total);

      final got = await repo.getById('f1');
      expect(got!.liters, liters);
      expect(got.pricePerLiter, price);
      expect(got.totalCost, total);
    });

    test('caller mandando synced é sobrescrito para pending', () async {
      final saved = await repo.create(sample(syncStatus: SyncStatus.synced));
      expect(saved.syncStatus, SyncStatus.pending);
    });
  });

  group('update', () {
    test('bumpa updated_at, preserva createdAt, marca pending', () async {
      final created = await repo.create(sample());

      fakeNow = DateTime.utc(2026, 5, 23, 11);

      // Repo sempre marca pending — usa qualquer syncStatus aqui só pra mostrar
      // que será sobrescrito.
      final updated = await repo.update(
        created.copyWith(odometer: 45200, syncStatus: SyncStatus.synced),
      );

      expect(updated.odometer, 45200);
      expect(updated.createdAt, created.createdAt); // preservado
      expect(updated.updatedAt, fakeNow); // bumpado
      expect(updated.syncStatus, SyncStatus.pending);
    });

    test('preserva precisão decimal no update', () async {
      final created = await repo.create(
        sample(
          liters: Decimal.parse('30'),
          pricePerLiter: Decimal.parse('5'),
          totalCost: Decimal.parse('150'),
        ),
      );

      fakeNow = DateTime.utc(2026, 5, 23, 11);

      final updated = await repo.update(
        created.copyWith(
          liters: Decimal.parse('43.219'),
          totalCost: Decimal.parse('250.634781'),
        ),
      );

      expect(updated.liters, Decimal.parse('43.219'));
      expect(updated.totalCost, Decimal.parse('250.634781'));
    });

    test('lança StateError quando id não existe', () async {
      expect(() => repo.update(sample(id: 'fantasma')), throwsStateError);
    });

    test('lança StateError quando soft-deletado', () async {
      await repo.create(sample());
      await repo.softDelete('f1');

      expect(
        () => repo.update(sample().copyWith(odometer: 99999)),
        throwsStateError,
      );
    });
  });

  group('softDelete', () {
    test('marca deleted_at e esconde dos reads', () async {
      await repo.create(sample());

      fakeNow = DateTime.utc(2026, 5, 23, 12);
      await repo.softDelete('f1');

      expect(await repo.getById('f1'), isNull);
      expect(await repo.listByVehicle('v1'), isEmpty);
    });

    test('é idempotente — não sobrescreve deleted_at original', () async {
      await repo.create(sample());

      fakeNow = DateTime.utc(2026, 5, 23, 12);
      await repo.softDelete('f1');

      final rawFirst = await (db.select(
        db.fuelEntries,
      )..where((t) => t.id.equals('f1'))).getSingle();
      final firstDeletedAt = rawFirst.deletedAt;

      fakeNow = DateTime.utc(2026, 5, 23, 13);
      await repo.softDelete('f1');

      final rawSecond = await (db.select(
        db.fuelEntries,
      )..where((t) => t.id.equals('f1'))).getSingle();
      expect(rawSecond.deletedAt, firstDeletedAt);
    });
  });

  group('listByVehicle', () {
    test('ordena por date DESC e exclui soft-deletados', () async {
      await repo.create(sample(id: 'f1', date: DateTime.utc(2026, 5, 20)));
      await repo.create(sample(id: 'f2', date: DateTime.utc(2026, 5, 22)));
      await repo.create(sample(id: 'f3', date: DateTime.utc(2026, 5, 21)));

      await repo.softDelete('f2');

      final list = await repo.listByVehicle('v1');
      expect(list.map((e) => e.id), ['f3', 'f1']); // 22 deletado; 21 > 20
    });

    test('isolamento por vehicleId', () async {
      await repo.create(sample(id: 'f1', vehicleId: 'v1'));
      await repo.create(sample(id: 'f2', vehicleId: 'v2'));

      expect((await repo.listByVehicle('v1')).map((e) => e.id), ['f1']);
      expect((await repo.listByVehicle('v2')).map((e) => e.id), ['f2']);
    });

    test(
      'datas iguais, odômetros iguais: ordem terciária por createdAt DESC',
      () async {
        final sameDate = DateTime.utc(2026, 5, 23);

        fakeNow = DateTime.utc(2026, 5, 23, 10);
        await repo.create(sample(id: 'f1', date: sameDate));

        fakeNow = DateTime.utc(2026, 5, 23, 11);
        await repo.create(sample(id: 'f2', date: sameDate));

        fakeNow = DateTime.utc(2026, 5, 23, 12);
        await repo.create(sample(id: 'f3', date: sameDate));

        final list = await repo.listByVehicle('v1');
        expect(list.map((e) => e.id), ['f3', 'f2', 'f1']);
      },
    );

    test(
      'datas iguais, odômetros diferentes: secundária por odômetro DESC '
      '(maior km no topo — semanticamente "mais tarde na vida do carro")',
      () async {
        final sameDate = DateTime.utc(2026, 5, 23);

        // Cadastra em ordem mista pra provar que não é ordem de inserção.
        await repo.create(sample(id: 'low', date: sameDate, odometer: 1100));
        await repo.create(sample(id: 'high', date: sameDate, odometer: 1300));
        await repo.create(sample(id: 'mid', date: sameDate, odometer: 1200));

        final list = await repo.listByVehicle('v1');
        expect(list.map((e) => e.id), ['high', 'mid', 'low']);
      },
    );

    test(
      'ordenação combinada: data primeiro, createdAt como tiebreaker',
      () async {
        // f1: data antiga.
        fakeNow = DateTime.utc(2026, 5, 23, 10);
        await repo.create(sample(id: 'f1', date: DateTime.utc(2026, 5, 20)));

        // f2 e f3: mesma data nova, criadas em ordem.
        fakeNow = DateTime.utc(2026, 5, 23, 11);
        await repo.create(sample(id: 'f2', date: DateTime.utc(2026, 5, 22)));

        fakeNow = DateTime.utc(2026, 5, 23, 12);
        await repo.create(sample(id: 'f3', date: DateTime.utc(2026, 5, 22)));

        final list = await repo.listByVehicle('v1');
        // Esperado: f3 (data 22, mais recente cadastrado), f2 (data 22, antes),
        // f1 (data 20, mais antiga).
        expect(list.map((e) => e.id), ['f3', 'f2', 'f1']);
      },
    );
  });

  group('watchByVehicle', () {
    test('emite inicial e em cada mutação', () async {
      final stream = repo.watchByVehicle('v1');

      final emissions = <List<String>>[];
      final sub = stream.listen((list) {
        emissions.add(list.map((e) => e.id).toList());
      });

      await Future<void>.delayed(const Duration(milliseconds: 20));

      await repo.create(sample(id: 'f1'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeNow = fakeNow.add(const Duration(minutes: 1));
      await repo.update(sample(id: 'f1').copyWith(odometer: 99));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      fakeNow = fakeNow.add(const Duration(minutes: 1));
      await repo.softDelete('f1');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await sub.cancel();

      expect(emissions.length, greaterThanOrEqualTo(4));
      expect(emissions.first, isEmpty);
      expect(emissions[1], ['f1']);
      expect(emissions.last, isEmpty);
    });
  });
}
