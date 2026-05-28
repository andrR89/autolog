import 'package:autolog/data/local/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.X — Schema v13 com tabela trips.

void main() {
  group('Schema v13', () {
    test('schemaVersion é ao menos 13 (agora 14 com notif prefs)', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, greaterThanOrEqualTo(13));
      db.close();
    });

    test('allTables contém ao menos 15 tabelas (agora 16 com vehicle_members)', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.allTables.length, greaterThanOrEqualTo(15));
      db.close();
    });

    test('trips aceita insert com todos os campos', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 24, 10);

      await db.into(db.trips).insert(
            TripsCompanion.insert(
              id: 'trip-1',
              vehicleId: 'v1',
              name: 'Floripa',
              startDate: DateTime.utc(2026, 5, 1),
              endDate: DateTime.utc(2026, 5, 7),
              notes: const drift.Value('Férias'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final rows = await db.select(db.trips).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'trip-1');
      expect(rows.first.vehicleId, 'v1');
      expect(rows.first.name, 'Floripa');
      expect(rows.first.notes, 'Férias');
      expect(rows.first.deletedAt, isNull);
      await db.close();
    });

    test('trips notes é nullable', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 24, 10);

      await db.into(db.trips).insert(
            TripsCompanion.insert(
              id: 'trip-1',
              vehicleId: 'v1',
              name: 'Serra',
              startDate: DateTime.utc(2026, 5, 1),
              endDate: DateTime.utc(2026, 5, 3),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final row = await db.select(db.trips).getSingle();
      expect(row.notes, isNull);
      await db.close();
    });

    test('trips deletedAt é nullable (soft delete support)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 24, 10);

      await db.into(db.trips).insert(
            TripsCompanion.insert(
              id: 'trip-1',
              vehicleId: 'v1',
              name: 'Viagem',
              startDate: now,
              endDate: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final deleteTime = DateTime.utc(2026, 5, 25);
      await (db.update(db.trips)..where((t) => t.id.equals('trip-1'))).write(
        TripsCompanion(
          deletedAt: drift.Value(deleteTime),
          updatedAt: drift.Value(deleteTime),
        ),
      );

      final row = await db.select(db.trips).getSingle();
      expect(row.deletedAt!.toUtc(), deleteTime);
      await db.close();
    });

    test('trips PK impede duplicatas', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 24, 10);

      final companion = TripsCompanion.insert(
        id: 'trip-1',
        vehicleId: 'v1',
        name: 'Viagem',
        startDate: now,
        endDate: now,
        createdAt: now,
        updatedAt: now,
      );

      await db.into(db.trips).insert(companion);
      // Segunda inserção com mesmo PK deve falhar.
      expect(
        () => db.into(db.trips).insert(companion),
        throwsA(anything),
      );
      await db.close();
    });
  });

  group('Migration v12 → v13', () {
    test('cria tabela trips na migration (simulação manual)', () async {
      final raw = NativeDatabase.memory();
      final legacyDb = _LegacyDbV12(raw);

      // Simula criação da tabela como a migration faria.
      await legacyDb.customStatement('''
        CREATE TABLE trips (
          id TEXT NOT NULL PRIMARY KEY,
          vehicle_id TEXT NOT NULL,
          name TEXT NOT NULL,
          start_date INTEGER NOT NULL,
          end_date INTEGER NOT NULL,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER
        )
      ''');

      await legacyDb.customStatement('''
        INSERT INTO trips (id, vehicle_id, name, start_date, end_date,
                           created_at, updated_at)
        VALUES ('t1', 'v1', 'Floripa', 0, 0, 0, 0)
      ''');

      final rows =
          await legacyDb.customSelect('SELECT * FROM trips').get();
      expect(rows.single.data['id'], 't1');
      expect(rows.single.data['name'], 'Floripa');
      expect(rows.single.data['notes'], isNull);
      expect(rows.single.data['deleted_at'], isNull);

      await legacyDb.close();
    });
  });
}

class _LegacyDbV12 extends drift.GeneratedDatabase {
  _LegacyDbV12(super.executor);

  @override
  int get schemaVersion => 12;

  @override
  Iterable<drift.TableInfo<drift.Table, dynamic>> get allTables => const [];

  @override
  drift.DriftDatabaseOptions get options => const drift.DriftDatabaseOptions();
}
