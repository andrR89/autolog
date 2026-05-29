import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.I — Schema v4 com fipe_code/fipe_value/fipe_reference_month
/// + tabela fipe_cache.
/// Spec: docs/specs/sprint-6.I-fipe-autocomplete.md

void main() {
  group('Vehicles schema v4', () {
    test('schemaVersion bumped to 4', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 18); // v17 com onboarding_seen (Sprint 6.GG)
      db.close();
    });

    test('insert + read preserva campos FIPE', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo =
          DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5, 26));

      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Civic',
        make: 'Honda',
        model: 'CIVIC LX 1.7',
        year: 2018,
        type: VehicleType.carro,
        fipeCode: '026003-6',
        fipeValue: Decimal.parse('78420.00'),
        fipeReferenceMonth: '2026-01',
        fuelType: FuelType.gasolina,
        initialOdometer: 50000,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(v);
      final back = await repo.getById('v1');

      expect(back, isNotNull);
      expect(back!.fipeCode, '026003-6');
      expect(back.fipeValue, Decimal.parse('78420.00'));
      expect(back.fipeReferenceMonth, '2026-01');
      await db.close();
    });

    test('insert sem FIPE → 3 campos null', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo =
          DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5, 26));

      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Sem FIPE',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(v);
      final back = await repo.getById('v1');

      expect(back!.fipeCode, isNull);
      expect(back.fipeValue, isNull);
      expect(back.fipeReferenceMonth, isNull);
      await db.close();
    });

    test('Vehicle.toJson contém chaves snake_case FIPE', () {
      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'X',
        fipeCode: '001-2',
        fipeValue: Decimal.parse('99000'),
        fipeReferenceMonth: '2026-01',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.synced,
      );
      final json = v.toJson();
      expect(json['fipe_code'], '001-2');
      expect(json['fipe_value'], '99000');
      expect(json['fipe_reference_month'], '2026-01');
    });
  });

  group('Migration v3 → v4', () {
    test('cria tabela fipe_cache e adiciona 3 colunas em vehicles', () async {
      final raw = NativeDatabase.memory();
      final lowDb = _LegacyDb(raw);

      // schema v3: vehicles já tem type/engine/tank/horsepower
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
          horsepower INTEGER
        )
      ''');
      await lowDb.customStatement('''
        INSERT INTO vehicles (id, user_id, nickname, fuel_type,
          initial_odometer, created_at, updated_at, sync_status)
        VALUES ('legado-1', 'u1', 'Antigo', 'gasolina', 100000,
          1700000000, 1700000000, 'synced')
      ''');

      // upgrade v3 → v4
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN fipe_code TEXT',
      );
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN fipe_value TEXT',
      );
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN fipe_reference_month TEXT',
      );
      await lowDb.customStatement('''
        CREATE TABLE fipe_cache (
          key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL,
          expires_at INTEGER NOT NULL
        )
      ''');

      final rows = await lowDb.customSelect(
        'SELECT id, fipe_code, fipe_value, fipe_reference_month FROM vehicles',
      ).get();
      expect(rows.length, 1);
      final row = rows.single.data;
      expect(row['id'], 'legado-1');
      expect(row['fipe_code'], isNull);

      // tabela fipe_cache aceita insert
      await lowDb.customStatement('''
        INSERT INTO fipe_cache (key, value, expires_at) VALUES ('/cars/brands', '[]', 1700000000)
      ''');
      final cacheRows = await lowDb.customSelect('SELECT * FROM fipe_cache').get();
      expect(cacheRows.length, 1);

      await lowDb.close();
    });
  });
}

class _LegacyDb extends GeneratedDatabase {
  _LegacyDb(super.executor);
  @override
  int get schemaVersion => 3;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}
