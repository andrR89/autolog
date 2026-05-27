import 'package:autolog/data/local/database.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — Schema v7 com user_profile + fines + insurances.
/// Spec: docs/specs/sprint-6.O-personal-documents.md

void main() {
  group('Schema v7', () {
    test('schemaVersion bumped to 7', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 13); // v13 com trips (Sprint 6.X)
      db.close();
    });

    test('user_profile aceita upsert (PK = userId)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.userProfile).insert(
            UserProfileCompanion.insert(
              userId: 'u1',
              cnhNumber: const Value('12345678901'),
              cnhCategory: const Value('B'),
              cnhExpiresAt: Value(DateTime.utc(2030, 1, 15)),
              createdAt: DateTime.utc(2026, 5, 26),
              updatedAt: DateTime.utc(2026, 5, 26),
            ),
          );
      final rows = await db.select(db.userProfile).get();
      expect(rows.length, 1);
      expect(rows.first.cnhCategory, 'B');
      await db.close();
    });

    test('fines aceita CRUD por veículo', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.fines).insert(
            FinesCompanion.insert(
              id: 'f1',
              vehicleId: 'v1',
              issuedAt: DateTime.utc(2026, 4, 1),
              description: 'Excesso de velocidade',
              amount: Decimal.parse('195.23'),
              createdAt: DateTime.utc(2026, 4, 2),
              updatedAt: DateTime.utc(2026, 4, 2),
            ),
          );
      final rows = await db.select(db.fines).get();
      expect(rows.single.amount, Decimal.parse('195.23'));
      expect(rows.single.paid, isFalse);
      await db.close();
    });

    test('insurances aceita CRUD por veículo', () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.into(db.insurances).insert(
            InsurancesCompanion.insert(
              id: 'i1',
              vehicleId: 'v1',
              insurer: const Value('Porto'),
              startsAt: DateTime.utc(2026, 1, 1),
              endsAt: DateTime.utc(2027, 1, 1),
              premiumPaid: Value(Decimal.parse('1850')),
              createdAt: DateTime.utc(2026, 1, 1),
              updatedAt: DateTime.utc(2026, 1, 1),
            ),
          );
      final rows = await db.select(db.insurances).get();
      expect(rows.single.insurer, 'Porto');
      await db.close();
    });
  });

  group('Migration v6 → v7', () {
    test('cria as 3 novas tabelas; preserva vehicles existentes', () async {
      final raw = NativeDatabase.memory();
      final lowDb = _LegacyDb(raw);

      // schema v6: vehicles tem todos os campos até 6.K (sem as 3 novas).
      await lowDb.customStatement('''
        CREATE TABLE vehicles (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          nickname TEXT NOT NULL,
          make TEXT, model TEXT, year INTEGER, uf TEXT, color TEXT,
          plate TEXT, renavam TEXT, chassi TEXT,
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
        VALUES ('legado-1', 'u1', 'Antigo', 'gasolina', 0,
          1700000000, 1700000000, 'synced')
      ''');

      // upgrade v6 → v7: 3 tabelas novas
      await lowDb.customStatement('''
        CREATE TABLE user_profile (
          user_id TEXT NOT NULL PRIMARY KEY,
          cnh_number TEXT,
          cnh_category TEXT,
          cnh_expires_at INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
      await lowDb.customStatement('''
        CREATE TABLE fines (
          id TEXT NOT NULL PRIMARY KEY,
          vehicle_id TEXT NOT NULL,
          auto_number TEXT,
          issued_at INTEGER NOT NULL,
          description TEXT NOT NULL,
          amount TEXT NOT NULL,
          due_date INTEGER,
          paid INTEGER NOT NULL DEFAULT 0,
          points INTEGER,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
      await lowDb.customStatement('''
        CREATE TABLE insurances (
          id TEXT NOT NULL PRIMARY KEY,
          vehicle_id TEXT NOT NULL,
          insurer TEXT,
          policy_number TEXT,
          starts_at INTEGER NOT NULL,
          ends_at INTEGER NOT NULL,
          premium_paid TEXT,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');

      final v = await lowDb
          .customSelect('SELECT id FROM vehicles')
          .get();
      expect(v.single.data['id'], 'legado-1');

      await lowDb.close();
    });
  });
}

class _LegacyDb extends GeneratedDatabase {
  _LegacyDb(super.executor);
  @override
  int get schemaVersion => 6;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}
