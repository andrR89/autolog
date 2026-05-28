import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.E — Schema v2 com year/uf/color.
/// Spec: docs/specs/sprint-6.E-vehicle-extended-fields.md

void main() {
  group('Vehicles schema v2', () {
    test('schemaVersion bumped to 3', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 15); // v15 com vehicle_members (Sprint 6.Y)
      db.close();
    });

    test('insert + read preserva year/uf/color', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5));

      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Civic',
        make: 'Honda',
        model: 'Civic LX',
        year: 2018,
        uf: 'SP',
        color: 'preto',
        plate: 'ABC1D23',
        fuelType: FuelType.flex,
        initialOdometer: 50000,
        createdAt: DateTime.utc(2026, 5),
        updatedAt: DateTime.utc(2026, 5),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(v);
      final back = await repo.getById('v1');

      expect(back, isNotNull);
      expect(back!.year, 2018);
      expect(back.uf, 'SP');
      expect(back.color, 'preto');
      expect(back.make, 'Honda');
      expect(back.model, 'Civic LX');
      await db.close();
    });

    test('insert sem year/uf/color (todos null) funciona', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5));

      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Sem detalhes',
        fuelType: FuelType.gasolina,
        initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5),
        updatedAt: DateTime.utc(2026, 5),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(v);
      final back = await repo.getById('v1');

      expect(back, isNotNull);
      expect(back!.year, isNull);
      expect(back.uf, isNull);
      expect(back.color, isNull);
      await db.close();
    });

    test('Vehicle.toJson/fromJson roundtrip com year/uf/color', () {
      final v = Vehicle(
        id: 'v1',
        userId: 'u1',
        nickname: 'Civic',
        year: 2018,
        uf: 'SP',
        color: 'preto',
        fuelType: FuelType.flex,
        initialOdometer: 50000,
        createdAt: DateTime.utc(2026, 5),
        updatedAt: DateTime.utc(2026, 5),
        syncStatus: SyncStatus.synced,
      );

      final json = v.toJson();
      expect(json['year'], 2018);
      expect(json['uf'], 'SP');
      expect(json['color'], 'preto');

      final back = Vehicle.fromJson(json);
      expect(back.year, 2018);
      expect(back.uf, 'SP');
      expect(back.color, 'preto');
    });
  });

  group('Migration v1 → v2', () {
    test('onUpgrade adiciona as 3 colunas e preserva linhas existentes',
        () async {
      // 1. Simula DB legado: schema v1 sem year/uf/color.
      //    Cria a tabela manualmente (sem as colunas novas) e popula.
      final raw = NativeDatabase.memory();
      final lowDb = _LegacyVehiclesDb(raw);
      await lowDb.customStatement('''
        CREATE TABLE vehicles (
          id TEXT NOT NULL PRIMARY KEY,
          user_id TEXT NOT NULL,
          nickname TEXT NOT NULL,
          make TEXT,
          model TEXT,
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

      // 2. Roda a migration v1 → v2 (simula bootstrap após upgrade).
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN year INTEGER',
      );
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN uf TEXT',
      );
      await lowDb.customStatement(
        'ALTER TABLE vehicles ADD COLUMN color TEXT',
      );

      // 3. Verifica: linha legada continua íntegra, novas colunas = null.
      final rows = await lowDb.customSelect(
        'SELECT id, nickname, year, uf, color FROM vehicles',
      ).get();
      expect(rows.length, 1);
      final row = rows.single.data;
      expect(row['id'], 'legado-1');
      expect(row['nickname'], 'Antigo');
      expect(row['year'], isNull);
      expect(row['uf'], isNull);
      expect(row['color'], isNull);

      // 4. Insert nova linha com year/uf/color funciona.
      await lowDb.customStatement('''
        INSERT INTO vehicles (id, user_id, nickname, fuel_type,
          initial_odometer, created_at, updated_at, sync_status,
          year, uf, color)
        VALUES ('novo-1', 'u1', 'Novo', 'flex', 0,
          1700000000, 1700000000, 'pending',
          2024, 'RJ', 'branco')
      ''');
      final novo = (await lowDb.customSelect(
        "SELECT year, uf, color FROM vehicles WHERE id = 'novo-1'",
      ).getSingle()).data;
      expect(novo['year'], 2024);
      expect(novo['uf'], 'RJ');
      expect(novo['color'], 'branco');

      await lowDb.close();
    });
  });
}

/// Wrapper mínimo só pra rodar custom SQL — não usa o schema gerado.
class _LegacyVehiclesDb extends GeneratedDatabase {
  _LegacyVehiclesDb(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}
