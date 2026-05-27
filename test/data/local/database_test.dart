import 'package:autolog/data/local/converters.dart';
import 'package:autolog/data/local/database.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 0.2 — Schema Drift das 5 tabelas.
/// Spec: docs/specs/sprint-0.2-drift-schema.md
void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 5, 22, 12);

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('schema', () {
    test('abre com schemaVersion 12 e expõe exatamente 14 tabelas', () {
      expect(db.schemaVersion, 12); // v12 com user_settings (Sprint 6.AA)
      expect(db.allTables.length, 14); // +UserSettings
    });
  });

  group('enums — wire values seguem ARCHITECTURE §3', () {
    test('valores canônicos de string', () {
      expect(FuelType.gasolina.wire, 'gasolina');
      expect(FuelSource.aiScan.wire, 'ai_scan');
      expect(ReminderType.porKm.wire, 'por_km');
      expect(ExpenseCategory.ipva.wire, 'ipva');
      expect(SyncStatus.pending.wire, 'pending');
    });

    test('fromWire é o inverso de wire', () {
      expect(FuelSource.fromWire('ai_scan'), FuelSource.aiScan);
      expect(ReminderType.fromWire('por_data'), ReminderType.porData);
      expect(SyncStatus.fromWire('synced'), SyncStatus.synced);
    });
  });

  group('vehicles', () {
    test(
      'roundtrip + defaults: sync_status=pending, deleted_at=null',
      () async {
        await db
            .into(db.vehicles)
            .insert(
              VehiclesCompanion.insert(
                id: 'v1',
                userId: 'u1',
                nickname: 'Meu Civic',
                fuelType: FuelType.flex,
                initialOdometer: 45000,
                createdAt: now,
                updatedAt: now,
              ),
            );

        final row = await db.select(db.vehicles).getSingle();
        expect(row.id, 'v1');
        expect(row.nickname, 'Meu Civic');
        expect(row.fuelType, FuelType.flex);
        expect(row.initialOdometer, 45000);
        expect(row.syncStatus, SyncStatus.pending);
        expect(row.deletedAt, isNull);
        expect(row.make, isNull);
      },
    );
  });

  group('fuel_entries — precisão decimal é sagrada', () {
    test('liters/price/total fazem roundtrip EXATO (sem double)', () async {
      final liters = Decimal.parse('43.219');
      final price = Decimal.parse('5.799');
      final total = Decimal.parse('250.634781');

      await db
          .into(db.fuelEntries)
          .insert(
            FuelEntriesCompanion.insert(
              id: 'f1',
              vehicleId: 'v1',
              date: now,
              odometer: 45100,
              liters: liters,
              pricePerLiter: price,
              totalCost: total,
              fullTank: true,
              fuelType: FuelType.gasolina,
              source: FuelSource.manual,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final row = await db.select(db.fuelEntries).getSingle();
      expect(row.liters, liters);
      expect(row.pricePerLiter, price);
      expect(row.totalCost, total);
      expect(row.fullTank, true);
      expect(row.source, FuelSource.manual);
      expect(row.receiptImageUrl, isNull);
    });

    test('coluna source grava o wire value (string crua)', () async {
      await db
          .into(db.fuelEntries)
          .insert(
            FuelEntriesCompanion.insert(
              id: 'f2',
              vehicleId: 'v1',
              date: now,
              odometer: 1,
              liters: Decimal.one,
              pricePerLiter: Decimal.one,
              totalCost: Decimal.one,
              fullTank: false,
              fuelType: FuelType.gasolina,
              source: FuelSource.aiScan,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final raw = await db
          .customSelect(
            'SELECT source FROM fuel_entries WHERE id = ?',
            variables: [const Variable('f2')],
          )
          .getSingle();
      expect(raw.data['source'], 'ai_scan');
    });
  });

  group('DecimalConverter', () {
    test('valor além da precisão de double faz roundtrip exato', () {
      const converter = DecimalConverter();
      final big = Decimal.parse('12345678901234.123456789');
      final stored = converter.toSql(big);
      expect(stored, isA<String>());
      expect(converter.fromSql(stored), big);
      expect(converter.fromSql(stored).toString(), '12345678901234.123456789');
    });
  });

  group('expenses', () {
    test('amount decimal exato, category enum, odometer nullable', () async {
      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'e1',
              vehicleId: 'v1',
              date: now,
              category: ExpenseCategory.ipva,
              description: 'IPVA 2026',
              amount: Decimal.parse('1234.56'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final row = await db.select(db.expenses).getSingle();
      expect(row.amount, Decimal.parse('1234.56'));
      expect(row.category, ExpenseCategory.ipva);
      expect(row.odometer, isNull);
    });
  });

  group('reminders', () {
    test('type enum, nullables, is_done default false', () async {
      await db
          .into(db.reminders)
          .insert(
            RemindersCompanion.insert(
              id: 'r1',
              vehicleId: 'v1',
              type: ReminderType.porKm,
              title: 'Troca de óleo',
              dueKm: const Value(50000),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final row = await db.select(db.reminders).getSingle();
      expect(row.type, ReminderType.porKm);
      expect(row.dueKm, 50000);
      expect(row.dueDate, isNull);
      expect(row.isDone, false);
    });
  });

  group('usage_quota', () {
    test(
      'PK user_id, defaults scan_count=0 / is_premium=false, month TEXT',
      () async {
        await db
            .into(db.usageQuota)
            .insert(UsageQuotaCompanion.insert(userId: 'u1', month: '2026-05'));

        final row = await db.select(db.usageQuota).getSingle();
        expect(row.userId, 'u1');
        expect(row.month, '2026-05');
        expect(row.scanCount, 0);
        expect(row.isPremium, false);
      },
    );
  });
}
