import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.H — Schema v3 com type/engineDisplacementCc/tankCapacityL/horsepower.
/// Spec: docs/specs/sprint-6.H-vehicle-type-and-specs.md

void main() {
  group('Vehicles schema v3', () {
    test('schemaVersion bumped to 3', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 14); // v14 com notif prefs (Sprint 6.W.4)
      db.close();
    });

    test('insert + read preserva type/engineCc/tank/horsepower', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo =
          DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5, 26));

      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Civic',
        make: 'Honda',
        model: 'Civic LX',
        year: 2018,
        uf: 'SP',
        color: 'preto',
        type: VehicleType.carro,
        engineDisplacementCc: 1600,
        tankCapacityL: Decimal.parse('47.0'),
        horsepower: 124,
        plate: 'ABC1D23',
        fuelType: FuelType.flex,
        initialOdometer: 50000,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(v);
      final back = await repo.getById('v1');

      expect(back, isNotNull);
      expect(back!.type, VehicleType.carro);
      expect(back.engineDisplacementCc, 1600);
      expect(back.tankCapacityL, Decimal.parse('47.0'));
      expect(back.horsepower, 124);
      await db.close();
    });

    test('insert moto com tank decimal não-inteiro', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo =
          DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5, 26));

      final v = Vehicle(
        id: 'm1',
        userId: 'u1',
        nickname: 'Yamaha XJ6',
        type: VehicleType.moto,
        engineDisplacementCc: 600,
        tankCapacityL: Decimal.parse('17.3'),
        horsepower: 78,
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(v);
      final back = await repo.getById('m1');

      expect(back!.type, VehicleType.moto);
      expect(back.tankCapacityL, Decimal.parse('17.3'));
      await db.close();
    });

    test('insert sem novos campos → type default carro, demais null', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo =
          DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5, 26));

      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Antigo',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(v);
      final back = await repo.getById('v1');

      expect(back!.type, VehicleType.carro);
      expect(back.engineDisplacementCc, isNull);
      expect(back.tankCapacityL, isNull);
      expect(back.horsepower, isNull);
      await db.close();
    });

    test('Vehicle.toJson/fromJson roundtrip com novos campos', () {
      final original = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Civic',
        type: VehicleType.carro,
        engineDisplacementCc: 1600,
        tankCapacityL: Decimal.parse('47.0'),
        horsepower: 124,
        fuelType: FuelType.flex,
        initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.synced,
      );

      final json = original.toJson();
      expect(json['type'], 'carro');
      expect(json['engine_displacement_cc'], 1600);
      // Decimal.parse('47.0').toString() normaliza para '47' (biblioteca decimal
      // remove zeros à direita). O roundtrip numérico é preservado.
      expect(json['tank_capacity_l'], '47');
      expect(json['horsepower'], 124);

      final back = Vehicle.fromJson(json);
      expect(back.type, VehicleType.carro);
      expect(back.engineDisplacementCc, 1600);
      expect(back.tankCapacityL, Decimal.parse('47.0'));
      expect(back.horsepower, 124);
    });
  });

  group('Migration v2 → v3', () {
    test('onUpgrade adiciona 4 colunas, preserva linha legada com type=carro',
        () async {
      // 1. Simula DB v2: vehicles com year/uf/color mas sem type/engineCc/tank/hp.
      final raw = NativeDatabase.memory();
      final lowDb = _LegacyVehiclesDb(raw);
      await lowDb.customStatement('''
        CREATE TABLE vehicles (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          nickname TEXT NOT NULL,
          make TEXT,
          model TEXT,
          year INTEGER,
          uf TEXT,
          color TEXT,
          plate TEXT,
          fuel_type TEXT NOT NULL,
          initial_odometer INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
      await lowDb.customStatement('''
        INSERT INTO vehicles (id, user_id, nickname, fuel_type,
          initial_odometer, created_at, updated_at, sync_status)
        VALUES ('legado-1', 'u1', 'Antigo', 'gasolina', 100000,
          1700000000, 1700000000, 'synced')
      ''');

      // 2. Roda migration v2 → v3 manual.
      await lowDb.customStatement(
        "ALTER TABLE vehicles ADD COLUMN type TEXT NOT NULL DEFAULT 'carro'",
      );
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN engine_displacement_cc INTEGER',
      );
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN tank_capacity_l TEXT',
      );
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN horsepower INTEGER',
      );

      // 3. Linha legada preservada, type default carro.
      final rows = await lowDb.customSelect(
        'SELECT id, type, engine_displacement_cc, tank_capacity_l, horsepower FROM vehicles',
      ).get();
      expect(rows.length, 1);
      final row = rows.single.data;
      expect(row['id'], 'legado-1');
      expect(row['type'], 'carro');
      expect(row['engine_displacement_cc'], isNull);
      expect(row['tank_capacity_l'], isNull);
      expect(row['horsepower'], isNull);

      // 4. Insert moto nova com todos os campos.
      await lowDb.customStatement('''
        INSERT INTO vehicles (id, user_id, nickname, fuel_type,
          initial_odometer, created_at, updated_at, sync_status,
          type, engine_displacement_cc, tank_capacity_l, horsepower)
        VALUES ('m1', 'u1', 'Yamaha', 'gasolina', 0,
          1700000000, 1700000000, 'pending',
          'moto', 600, '17.3', 78)
      ''');
      final moto = (await lowDb.customSelect(
        "SELECT type, engine_displacement_cc, tank_capacity_l, horsepower FROM vehicles WHERE id = 'm1'",
      ).getSingle()).data;
      expect(moto['type'], 'moto');
      expect(moto['engine_displacement_cc'], 600);
      expect(moto['tank_capacity_l'], '17.3');
      expect(moto['horsepower'], 78);

      await lowDb.close();
    });
  });
}

class _LegacyVehiclesDb extends GeneratedDatabase {
  _LegacyVehiclesDb(super.executor);
  @override
  int get schemaVersion => 2;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}
