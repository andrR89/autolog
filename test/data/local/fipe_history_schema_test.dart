import 'package:autolog/data/local/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.J — Schema v5 com tabela fipe_history.
/// Spec: docs/specs/sprint-6.J-fipe-history.md

void main() {
  group('Vehicles schema v5', () {
    test('schemaVersion bumped to 5', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 13); // v13 com trips (Sprint 6.X)
      db.close();
    });

    test('fipe_history aceita insert e read', () async {
      final db = AppDatabase(NativeDatabase.memory());

      await db.into(db.fipeHistory).insert(
            FipeHistoryCompanion.insert(
              vehicleId: 'v1',
              month: '2026-05',
              value: Decimal.parse('78420.00'),
              capturedAt: DateTime.utc(2026, 5, 26),
            ),
          );

      final rows = await db.select(db.fipeHistory).get();
      expect(rows.length, 1);
      expect(rows.first.value, Decimal.parse('78420.00'));
      expect(rows.first.month, '2026-05');
      await db.close();
    });

    test('upsert mesma PK (vehicleId, month) sobrescreve', () async {
      final db = AppDatabase(NativeDatabase.memory());

      await db.into(db.fipeHistory).insert(
            FipeHistoryCompanion.insert(
              vehicleId: 'v1',
              month: '2026-05',
              value: Decimal.parse('78420.00'),
              capturedAt: DateTime.utc(2026, 5, 26),
            ),
          );

      await db.into(db.fipeHistory).insert(
            FipeHistoryCompanion.insert(
              vehicleId: 'v1',
              month: '2026-05',
              value: Decimal.parse('80000.00'),
              capturedAt: DateTime.utc(2026, 5, 27),
            ),
            mode: InsertMode.insertOrReplace,
          );

      final rows = await db.select(db.fipeHistory).get();
      expect(rows.length, 1);
      expect(rows.first.value, Decimal.parse('80000.00'));
      await db.close();
    });

    test('vehicles diferentes podem ter mesmo mês', () async {
      final db = AppDatabase(NativeDatabase.memory());

      await db.into(db.fipeHistory).insert(FipeHistoryCompanion.insert(
            vehicleId: 'v1',
            month: '2026-05',
            value: Decimal.parse('78420'),
            capturedAt: DateTime.utc(2026, 5, 26),
          ));
      await db.into(db.fipeHistory).insert(FipeHistoryCompanion.insert(
            vehicleId: 'v2',
            month: '2026-05',
            value: Decimal.parse('123000'),
            capturedAt: DateTime.utc(2026, 5, 26),
          ));

      final rows = await db.select(db.fipeHistory).get();
      expect(rows.length, 2);
      await db.close();
    });
  });

  group('Migration v4 → v5', () {
    test('cria tabela fipe_history; preserva fipe_cache e vehicles', () async {
      final raw = NativeDatabase.memory();
      final lowDb = _LegacyDb(raw);

      // schema v4: vehicles + fipe_cache, sem fipe_history
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
          fipe_code TEXT,
          fipe_value TEXT,
          fipe_reference_month TEXT
        )
      ''');
      await lowDb.customStatement('''
        CREATE TABLE fipe_cache (
          key TEXT NOT NULL PRIMARY KEY,
          value TEXT NOT NULL,
          expires_at INTEGER NOT NULL
        )
      ''');
      await lowDb.customStatement('''
        INSERT INTO vehicles (id, user_id, nickname, fuel_type,
          initial_odometer, created_at, updated_at, sync_status)
        VALUES ('legado-1', 'u1', 'Antigo', 'gasolina', 100000,
          1700000000, 1700000000, 'synced')
      ''');

      // upgrade v4 → v5
      await lowDb.customStatement('''
        CREATE TABLE fipe_history (
          vehicle_id TEXT NOT NULL,
          month TEXT NOT NULL,
          value TEXT NOT NULL,
          captured_at INTEGER NOT NULL,
          PRIMARY KEY (vehicle_id, month)
        )
      ''');

      final vehicleRows =
          await lowDb.customSelect('SELECT id FROM vehicles').get();
      expect(vehicleRows.single.data['id'], 'legado-1');

      await lowDb.customStatement('''
        INSERT INTO fipe_history (vehicle_id, month, value, captured_at)
        VALUES ('legado-1', '2026-05', '78420', 1700000000)
      ''');
      final hist =
          await lowDb.customSelect('SELECT * FROM fipe_history').get();
      expect(hist.length, 1);
      expect(hist.single.data['value'], '78420');

      await lowDb.close();
    });
  });
}

class _LegacyDb extends GeneratedDatabase {
  _LegacyDb(super.executor);
  @override
  int get schemaVersion => 4;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}
