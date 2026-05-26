import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/json_converters.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/usage_quota.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 0.3 — Modelos de domínio (freezed + json_serializable).
/// Spec: docs/specs/sprint-0.3-domain-models.md
void main() {
  final now = DateTime.utc(2026, 5, 22, 12);

  group('Vehicle', () {
    final v = Vehicle(
      id: 'v1',
      userId: 'u1',
      nickname: 'Meu Civic',
      fuelType: FuelType.flex,
      initialOdometer: 45000,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    test('roundtrip JSON, snake_case, fuel_type por wire, opcionais nulos', () {
      final json = v.toJson();
      expect(json.containsKey('user_id'), true);
      expect(json.containsKey('initial_odometer'), true);
      expect(json['fuel_type'], 'flex');
      expect(json['deleted_at'], isNull);
      expect(Vehicle.fromJson(json), v);
      expect(v.make, isNull);
    });

    test('copyWith e igualdade de valor', () {
      final v2 = v.copyWith(nickname: 'Outro');
      expect(v2.nickname, 'Outro');
      expect(v2, isNot(v));
      expect(v.copyWith(), v);
    });

    test('sync_status serializa por wire', () {
      expect(v.toJson()['sync_status'], 'pending');
      expect(
        v.copyWith(syncStatus: SyncStatus.synced).toJson()['sync_status'],
        'synced',
      );
    });
  });

  group('FuelEntry — precisão decimal é sagrada', () {
    final f = FuelEntry(
      id: 'f1',
      vehicleId: 'v1',
      date: now,
      odometer: 45100,
      liters: Decimal.parse('43.219'),
      pricePerLiter: Decimal.parse('5.799'),
      totalCost: Decimal.parse('250.634781'),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.aiScan,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );

    test('decimais vão como String no JSON e fazem roundtrip exato', () {
      final json = f.toJson();
      expect(json['liters'], '43.219');
      expect(json['liters'], isA<String>());
      expect(json['price_per_liter'], '5.799');
      expect(json['full_tank'], true);
      expect(json['source'], 'ai_scan');

      final back = FuelEntry.fromJson(json);
      expect(back.liters, Decimal.parse('43.219'));
      expect(back.pricePerLiter, Decimal.parse('5.799'));
      expect(back.totalCost, Decimal.parse('250.634781'));
      expect(back.source, FuelSource.aiScan);
      expect(back, f);
    });
  });

  group('DecimalJsonConverter', () {
    test('roundtrip exato além da precisão de double; toJson é String', () {
      const c = DecimalJsonConverter();
      final big = Decimal.parse('12345678901234.123456789');
      final j = c.toJson(big);
      expect(j, isA<String>());
      expect(c.fromJson(j), big);
    });
  });

  group('Expense', () {
    test('amount decimal exato, category por wire, odometer nullable', () {
      final e = Expense(
        id: 'e1',
        vehicleId: 'v1',
        date: now,
        category: ExpenseCategory.ipva,
        description: 'IPVA 2026',
        amount: Decimal.parse('1234.56'),
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );
      final json = e.toJson();
      expect(json['category'], 'ipva');
      expect(json['amount'], '1234.56');

      final back = Expense.fromJson(json);
      expect(back.amount, Decimal.parse('1234.56'));
      expect(back.odometer, isNull);
      expect(back, e);
    });
  });

  group('Reminder', () {
    test('type por wire, nullables sobrevivem, is_done no JSON', () {
      final r = Reminder(
        id: 'r1',
        vehicleId: 'v1',
        type: ReminderType.porKm,
        title: 'Troca de óleo',
        isDone: false,
        createdAt: now,
        updatedAt: now,
        syncStatus: SyncStatus.pending,
      );
      final json = r.toJson();
      expect(json['type'], 'por_km');
      expect(json['due_km'], isNull);
      expect(json['due_date'], isNull);
      expect(json.containsKey('is_done'), true);

      final back = Reminder.fromJson(json);
      expect(back.dueKm, isNull);
      expect(back.dueDate, isNull);
      expect(back, r);
    });
  });

  group('UsageQuota', () {
    test('roundtrip e chaves snake_case', () {
      const q = UsageQuota(
        userId: 'u1',
        month: '2026-05',
        scanCount: 0,
        isPremium: false,
      );
      final json = q.toJson();
      expect(json.containsKey('user_id'), true);
      expect(json.containsKey('scan_count'), true);
      expect(json.containsKey('is_premium'), true);
      expect(json['month'], '2026-05');
      expect(UsageQuota.fromJson(json), q);
    });
  });
}
