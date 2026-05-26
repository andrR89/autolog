import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/cost_per_km_calculator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.Q — custo por km + análise de tendência.
/// Spec: docs/specs/sprint-6.Q-cost-per-km-trend.md
FuelEntry _f({
  required String id,
  required int odometer,
  required String liters,
  required String total,
  DateTime? date,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date ?? DateTime.utc(2026, 5, 1),
      odometer: odometer,
      liters: Decimal.parse(liters),
      pricePerLiter: (Decimal.parse(total) / Decimal.parse(liters))
          .toDecimal(scaleOnInfinitePrecision: 4),
      totalCost: Decimal.parse(total),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date ?? DateTime.utc(2026, 5, 1),
      updatedAt: date ?? DateTime.utc(2026, 5, 1),
      syncStatus: SyncStatus.synced,
    );

Expense _x({
  required String id,
  required String amount,
  DateTime? date,
}) =>
    Expense(
      id: id,
      vehicleId: 'v1',
      date: date ?? DateTime.utc(2026, 5, 1),
      category: ExpenseCategory.manutencao,
      description: 'X',
      amount: Decimal.parse(amount),
      createdAt: date ?? DateTime.utc(2026, 5, 1),
      updatedAt: date ?? DateTime.utc(2026, 5, 1),
      syncStatus: SyncStatus.synced,
    );

void main() {
  group('computeCostMetrics', () {
    test('listas vazias → tudo zero e perKm null', () {
      final m = computeCostMetrics(fuels: const [], expenses: const []);
      expect(m.totalKm, 0);
      expect(m.fuelCost, Decimal.zero);
      expect(m.otherCost, Decimal.zero);
      expect(m.totalCost, Decimal.zero);
      expect(m.fuelCostPerKm, isNull);
      expect(m.totalCostPerKm, isNull);
    });

    test('1 fuel entry → totalKm 0 e perKm null (precisa baseline)', () {
      final m = computeCostMetrics(
        fuels: [_f(id: 'a', odometer: 10000, liters: '40', total: '200')],
        expenses: const [],
      );
      expect(m.totalKm, 0);
      expect(m.fuelCost, Decimal.parse('200'));
      expect(m.fuelCostPerKm, isNull);
      expect(m.totalCostPerKm, isNull);
    });

    test('2 fuel entries → totalKm = max - min, fuelCost = soma', () {
      final m = computeCostMetrics(
        fuels: [
          _f(id: 'a', odometer: 10000, liters: '40', total: '200'),
          _f(id: 'b', odometer: 10500, liters: '40', total: '240'),
        ],
        expenses: const [],
      );
      expect(m.totalKm, 500);
      expect(m.fuelCost, Decimal.parse('440'));
      expect(m.fuelCostPerKm, Decimal.parse('0.88'));
      expect(m.totalCostPerKm, Decimal.parse('0.88'));
    });

    test('expenses entram só no totalCost', () {
      final m = computeCostMetrics(
        fuels: [
          _f(id: 'a', odometer: 10000, liters: '40', total: '200'),
          _f(id: 'b', odometer: 10500, liters: '40', total: '240'),
        ],
        expenses: [_x(id: 'x1', amount: '100')],
      );
      expect(m.otherCost, Decimal.parse('100'));
      expect(m.totalCost, Decimal.parse('540'));
      expect(m.fuelCostPerKm, Decimal.parse('0.88'));
      expect(m.totalCostPerKm, Decimal.parse('1.08'));
    });

    test('precisão Decimal scale 4 em perKm com divisão inexata', () {
      // 100 / 333 = 0.30030030... → arredonda pra 0.3003
      final m = computeCostMetrics(
        fuels: [
          _f(id: 'a', odometer: 0, liters: '20', total: '50'),
          _f(id: 'b', odometer: 333, liters: '20', total: '50'),
        ],
        expenses: const [],
      );
      expect(m.totalKm, 333);
      expect(m.fuelCostPerKm, Decimal.parse('0.3003'));
    });

    test('ordem dos fuels não importa pro totalKm', () {
      final m = computeCostMetrics(
        fuels: [
          _f(id: 'b', odometer: 10500, liters: '40', total: '240'),
          _f(id: 'a', odometer: 10000, liters: '40', total: '200'),
        ],
        expenses: const [],
      );
      expect(m.totalKm, 500);
    });
  });
}
