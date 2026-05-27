import 'package:autolog/data/local/database.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.P — Schema v8 com station_name/station_brand em fuel_entries.
/// Spec: docs/specs/sprint-6.P-station-price-tracker.md

void main() {
  group('FuelEntries schema v8', () {
    test('schemaVersion bumped to 8', () {
      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, 11); // v9 com chat_messages (Sprint 6.T)
      db.close();
    });

    test('insert + read preserva stationName/stationBrand', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final vrepo = DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5));
      final repo =
          DriftFuelEntryRepository(db, now: () => DateTime.utc(2026, 5));

      await vrepo.create(Vehicle(
        id: 'v1', userId: 'u1', nickname: 'Civic',
        fuelType: FuelType.flex, initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5),
        updatedAt: DateTime.utc(2026, 5),
        syncStatus: SyncStatus.synced,
      ));

      final entry = FuelEntry(
        id: 'f1',
        vehicleId: 'v1',
        date: DateTime.utc(2026, 5, 26),
        odometer: 100,
        liters: Decimal.parse('40'),
        pricePerLiter: Decimal.parse('5.79'),
        totalCost: Decimal.parse('231.60'),
        fullTank: true,
        fuelType: FuelType.gasolina,
        source: FuelSource.manual,
        stationName: 'Posto Shell BR-101 km 87',
        stationBrand: 'Shell',
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.pending,
      );

      await repo.create(entry);
      final back = await repo.getById('f1');

      expect(back, isNotNull);
      expect(back!.stationName, 'Posto Shell BR-101 km 87');
      expect(back.stationBrand, 'Shell');
      await db.close();
    });

    test('insert sem station → null', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final vrepo = DriftVehicleRepository(db, now: () => DateTime.utc(2026, 5));
      final repo =
          DriftFuelEntryRepository(db, now: () => DateTime.utc(2026, 5));

      await vrepo.create(Vehicle(
        id: 'v1', userId: 'u1', nickname: 'X',
        fuelType: FuelType.gasolina, initialOdometer: 0,
        createdAt: DateTime.utc(2026, 5),
        updatedAt: DateTime.utc(2026, 5),
        syncStatus: SyncStatus.synced,
      ));

      await repo.create(FuelEntry(
        id: 'f1', vehicleId: 'v1',
        date: DateTime.utc(2026, 5, 26),
        odometer: 50,
        liters: Decimal.parse('30'),
        pricePerLiter: Decimal.parse('5'),
        totalCost: Decimal.parse('150'),
        fullTank: true,
        fuelType: FuelType.gasolina,
        source: FuelSource.manual,
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.pending,
      ));
      final back = await repo.getById('f1');
      expect(back!.stationName, isNull);
      expect(back.stationBrand, isNull);
      await db.close();
    });

    test('toJson inclui chaves snake_case', () {
      final e = FuelEntry(
        id: 'f1', vehicleId: 'v1',
        date: DateTime.utc(2026, 5, 26),
        odometer: 100,
        liters: Decimal.parse('40'),
        pricePerLiter: Decimal.parse('5.79'),
        totalCost: Decimal.parse('231.60'),
        fullTank: true,
        fuelType: FuelType.gasolina,
        source: FuelSource.manual,
        stationName: 'Posto Shell',
        stationBrand: 'Shell',
        createdAt: DateTime.utc(2026, 5, 26),
        updatedAt: DateTime.utc(2026, 5, 26),
        syncStatus: SyncStatus.synced,
      );
      final json = e.toJson();
      expect(json['station_name'], 'Posto Shell');
      expect(json['station_brand'], 'Shell');
    });
  });

  group('Migration v7 → v8', () {
    test('adiciona 2 colunas em fuel_entries, preserva linhas', () async {
      final raw = NativeDatabase.memory();
      final lowDb = _LegacyDb(raw);

      await lowDb.customStatement('''
        CREATE TABLE fuel_entries (
          id TEXT NOT NULL PRIMARY KEY,
          vehicle_id TEXT NOT NULL,
          date INTEGER NOT NULL,
          odometer INTEGER NOT NULL,
          liters TEXT NOT NULL,
          price_per_liter TEXT NOT NULL,
          total_cost TEXT NOT NULL,
          full_tank INTEGER NOT NULL,
          fuel_type TEXT NOT NULL,
          source TEXT NOT NULL,
          receipt_image_url TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
      await lowDb.customStatement('''
        INSERT INTO fuel_entries (id, vehicle_id, date, odometer, liters,
          price_per_liter, total_cost, full_tank, fuel_type, source,
          created_at, updated_at, sync_status)
        VALUES ('legado-1', 'v1', 1700000000, 100, '40', '5.79', '231.60',
          1, 'gasolina', 'manual', 1700000000, 1700000000, 'synced')
      ''');

      await lowDb.customStatement(
        'ALTER TABLE fuel_entries ADD COLUMN station_name TEXT',
      );
      await lowDb.customStatement(
        'ALTER TABLE fuel_entries ADD COLUMN station_brand TEXT',
      );

      final rows = await lowDb.customSelect(
        'SELECT id, station_name, station_brand FROM fuel_entries',
      ).get();
      expect(rows.length, 1);
      expect(rows.single.data['station_name'], isNull);
      expect(rows.single.data['station_brand'], isNull);

      await lowDb.close();
    });
  });
}

class _LegacyDb extends GeneratedDatabase {
  _LegacyDb(super.executor);
  @override
  int get schemaVersion => 7;
  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions();
}
