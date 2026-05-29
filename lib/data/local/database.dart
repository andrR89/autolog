import 'dart:io';

import 'package:autolog/data/local/converters.dart';
import 'package:autolog/data/local/tables.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Vehicles,
  FuelEntries,
  Expenses,
  Reminders,
  UsageQuota,
  FipeCache,
  FipeHistory,
  UserProfile,
  Fines,
  Insurances,
  ChatMessages,
  NotificationsLog,
  FiscalLookupCache,
  UserSettings,
  Trips,
  VehicleMembers,
  CalendarEventLinks,
])
class AppDatabase extends _$AppDatabase {
  /// Construtor testável: aceita qualquer [QueryExecutor].
  /// Em testes usa-se [NativeDatabase.memory()]; em produção usa-se um
  /// [LazyDatabase] com [path_provider] (a implementar em sprint posterior).
  AppDatabase(super.e);

  @override
  int get schemaVersion => 17;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(vehicles, vehicles.year);
        await m.addColumn(vehicles, vehicles.uf);
        await m.addColumn(vehicles, vehicles.color);
      }
      if (from < 3) {
        await m.addColumn(vehicles, vehicles.type);
        await m.addColumn(vehicles, vehicles.engineDisplacementCc);
        await m.addColumn(vehicles, vehicles.tankCapacityL);
        await m.addColumn(vehicles, vehicles.horsepower);
      }
      if (from < 4) {
        await m.addColumn(vehicles, vehicles.fipeCode);
        await m.addColumn(vehicles, vehicles.fipeValue);
        await m.addColumn(vehicles, vehicles.fipeReferenceMonth);
        await m.createTable(fipeCache);
      }
      if (from < 5) {
        await m.createTable(fipeHistory);
      }
      if (from < 6) {
        await m.addColumn(vehicles, vehicles.renavam);
        await m.addColumn(vehicles, vehicles.chassi);
      }
      if (from < 7) {
        await m.createTable(userProfile);
        await m.createTable(fines);
        await m.createTable(insurances);
      }
      if (from < 8) {
        await m.addColumn(fuelEntries, fuelEntries.stationName);
        await m.addColumn(fuelEntries, fuelEntries.stationBrand);
      }
      if (from < 9) {
        await m.createTable(chatMessages);
      }
      if (from < 10) {
        await m.createTable(notificationsLog);
      }
      if (from < 11) {
        await m.createTable(fiscalLookupCache);
      }
      if (from < 12) {
        await m.createTable(userSettings);
      }
      if (from < 13) {
        await m.createTable(trips);
      }
      if (from < 14) {
        await m.addColumn(userSettings, userSettings.notifConsumptionDrop);
        await m.addColumn(userSettings, userSettings.notifCnh);
        await m.addColumn(userSettings, userSettings.notifFiscal);
        await m.addColumn(userSettings, userSettings.notifRecapReady);
      }
      if (from < 15) {
        await m.createTable(vehicleMembers);
      }
      if (from < 16) {
        await m.createTable(calendarEventLinks);
      }
      if (from < 17) {
        await m.addColumn(userSettings, userSettings.onboardingSeen);
      }
    },
  );
}

/// Provider que expõe o singleton [AppDatabase] para o app em produção.
/// Em testes, crie [AppDatabase(NativeDatabase.memory())] diretamente.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = p.join(dir.path, 'autolog.db');
      return NativeDatabase(File(file));
    }),
  );
  ref.onDispose(db.close);
  return db;
});
