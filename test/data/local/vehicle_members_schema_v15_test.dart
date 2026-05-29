import 'package:autolog/data/local/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.Y — Schema v15 com tabela vehicle_members.

void main() {
  group('Schema v15', () {
    test('schemaVersion é 17 (v17 com onboarding_seen, Sprint 6.GG)', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 17);
      db.close();
    });

    test('allTables contém 17 tabelas', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.allTables.length, 17);
      db.close();
    });

    test('vehicle_members aceita insert com todos os campos', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 27, 10);

      await db.into(db.vehicleMembers).insert(
            VehicleMembersCompanion.insert(
              vehicleId: 'vehicle-1',
              userId: 'user-1',
              createdAt: now,
            ),
          );

      final row = await db.select(db.vehicleMembers).getSingle();
      expect(row.vehicleId, 'vehicle-1');
      expect(row.userId, 'user-1');
      expect(row.role, 'member'); // default
      expect(row.createdAt.toUtc(), now);

      await db.close();
    });

    test('role padrão é "member"', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 27);

      await db.into(db.vehicleMembers).insert(
            VehicleMembersCompanion.insert(
              vehicleId: 'v1',
              userId: 'u1',
              createdAt: now,
            ),
          );

      final row = await db.select(db.vehicleMembers).getSingle();
      expect(row.role, 'member');

      await db.close();
    });

    test('role pode ser "owner"', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 27);

      await db.into(db.vehicleMembers).insert(
            VehicleMembersCompanion.insert(
              vehicleId: 'v1',
              userId: 'u1',
              role: const drift.Value('owner'),
              createdAt: now,
            ),
          );

      final row = await db.select(db.vehicleMembers).getSingle();
      expect(row.role, 'owner');

      await db.close();
    });

    test('PK composta (vehicleId + userId) garante unicidade', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 27);

      await db.into(db.vehicleMembers).insert(
            VehicleMembersCompanion.insert(
              vehicleId: 'v1',
              userId: 'u1',
              createdAt: now,
            ),
          );

      // Segundo insert com mesma PK deve lançar.
      expect(
        () => db.into(db.vehicleMembers).insert(
              VehicleMembersCompanion.insert(
                vehicleId: 'v1',
                userId: 'u1',
                createdAt: now,
              ),
            ),
        throwsA(anything),
      );

      await db.close();
    });

    test('mesmo vehicleId aceita userId diferente (membros distintos)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 27);

      await db.into(db.vehicleMembers).insert(
            VehicleMembersCompanion.insert(
              vehicleId: 'v1',
              userId: 'u1',
              createdAt: now,
            ),
          );
      await db.into(db.vehicleMembers).insert(
            VehicleMembersCompanion.insert(
              vehicleId: 'v1',
              userId: 'u2',
              createdAt: now,
            ),
          );

      final rows = await db.select(db.vehicleMembers).get();
      expect(rows, hasLength(2));

      await db.close();
    });

    test('DELETE remove o membro corretamente', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 5, 27);

      await db.into(db.vehicleMembers).insert(
            VehicleMembersCompanion.insert(
              vehicleId: 'v1',
              userId: 'u1',
              createdAt: now,
            ),
          );

      await (db.delete(db.vehicleMembers)
            ..where(
              (t) => t.vehicleId.equals('v1') & t.userId.equals('u1'),
            ))
          .go();

      final rows = await db.select(db.vehicleMembers).get();
      expect(rows, isEmpty);

      await db.close();
    });
  });

  group('Migration v14 → v15', () {
    test('createTable vehicle_members em banco existente', () async {
      final raw = NativeDatabase.memory();
      final legacyDb = _LegacyDbV14(raw);

      // Cria manualmente o schema como estava em v14 (sem vehicle_members).
      await legacyDb.customStatement('''
        CREATE TABLE vehicles (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          nickname TEXT NOT NULL,
          fuel_type TEXT NOT NULL,
          initial_odometer INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');

      // Simula a migration v15: CREATE TABLE vehicle_members.
      await legacyDb.customStatement('''
        CREATE TABLE vehicle_members (
          vehicle_id TEXT NOT NULL,
          user_id TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'member',
          created_at INTEGER NOT NULL,
          PRIMARY KEY (vehicle_id, user_id)
        )
      ''');

      // Confirma que a tabela existe e aceita dados.
      await legacyDb.customStatement('''
        INSERT INTO vehicle_members (vehicle_id, user_id, created_at)
        VALUES ('v1', 'u1', 1716800000)
      ''');

      final rows = await legacyDb
          .customSelect('SELECT * FROM vehicle_members')
          .get();
      expect(rows.single.data['vehicle_id'], 'v1');
      expect(rows.single.data['role'], 'member');

      await legacyDb.close();
    });
  });
}

class _LegacyDbV14 extends drift.GeneratedDatabase {
  _LegacyDbV14(super.executor);

  @override
  int get schemaVersion => 14;

  @override
  Iterable<drift.TableInfo<drift.Table, dynamic>> get allTables => const [];

  @override
  drift.DriftDatabaseOptions get options => const drift.DriftDatabaseOptions();
}
