import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.K — Schema v6 com renavam/chassi.
/// Spec: docs/specs/sprint-6.K-scan-crlv.md

void main() {
  group('Vehicles schema v6', () {
    test('schemaVersion bumped to 6', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 12); // v12 com user_settings (Sprint 6.AA)
      db.close();
    });

    test('insert + read preserva renavam/chassi', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo =
          DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5, 26));

      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Civic',
        plate: 'ABC1D23',
        renavam: '12345678901',
        chassi: '9BWZZZ377VT004251',
        fuelType: FuelType.flex,
        initialOdometer: 50000,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(v);
      final back = await repo.getById('v1');

      expect(back, isNotNull);
      expect(back!.renavam, '12345678901');
      expect(back.chassi, '9BWZZZ377VT004251');
      await db.close();
    });

    test('insert sem renavam/chassi → null', () async {
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

      expect(back!.renavam, isNull);
      expect(back.chassi, isNull);
      await db.close();
    });

    test('Vehicle.toJson inclui renavam/chassi', () {
      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'X',
        renavam: '12345678901',
        chassi: '9BWZZZ377VT004251',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.synced,
      );
      final json = v.toJson();
      expect(json['renavam'], '12345678901');
      expect(json['chassi'], '9BWZZZ377VT004251');
    });
  });

  group('Migration v5 → v6', () {
    test('adiciona 2 colunas (renavam, chassi); preserva vehicles', () async {
      final raw = NativeDatabase.memory();
      final lowDb = _LegacyDb(raw);

      // schema v5: vehicles tem todos os campos até 6.J + tabelas fipe_cache e fipe_history.
      await lowDb.customStatement('''
        CREATE TABLE vehicles (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          nickname TEXT NOT NULL,
          make TEXT, model TEXT, year INTEGER, uf TEXT, color TEXT,
          plate TEXT,
          fuel_type TEXT NOT NULL,
          initial_odometer INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'pending',
          type TEXT NOT NULL DEFAULT 'carro',
          engine_displacement_cc INTEGER,
          tank_capacity_l TEXT,
          horsepower INTEGER,
          fipe_code TEXT, fipe_value TEXT, fipe_reference_month TEXT
        )
      ''');
      await lowDb.customStatement('''
        INSERT INTO vehicles (id, user_id, nickname, fuel_type,
          initial_odometer, created_at, updated_at, sync_status)
        VALUES ('legado-1', 'u1', 'Antigo', 'gasolina', 100000,
          1700000000, 1700000000, 'synced')
      ''');

      // upgrade v5 → v6
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN renavam TEXT',
      );
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN chassi TEXT',
      );

      final rows = await lowDb.customSelect(
        'SELECT id, renavam, chassi FROM vehicles',
      ).get();
      expect(rows.length, 1);
      expect(rows.single.data['renavam'], isNull);
      expect(rows.single.data['chassi'], isNull);

      await lowDb.close();
    });
  });
}

class _LegacyDb extends GeneratedDatabase {
  _LegacyDb(super.executor);
  @override
  int get schemaVersion => 5;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}
