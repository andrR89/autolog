import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/recap/recap_data.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.V — Recap mensal/semanal puro.
/// Spec: docs/specs/sprint-6.V-recap-wrapped.md

FuelEntry _f({
  required String id,
  required int odometer,
  required String liters,
  required String price,
  required DateTime date,
  String? brand,
  String? name,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: odometer,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse(price),
      totalCost: Decimal.parse(liters) * Decimal.parse(price),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      stationName: name,
      stationBrand: brand,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.synced,
    );

Expense _x({
  required String id,
  required String amount,
  required DateTime date,
  ExpenseCategory category = ExpenseCategory.manutencao,
}) =>
    Expense(
      id: id,
      vehicleId: 'v1',
      date: date,
      category: category,
      description: 'X',
      amount: Decimal.parse(amount),
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.synced,
    );

void main() {
  group('computeRecap', () {
    test('listas vazias → tudo zerado', () {
      final r = computeRecap(
        period: RecapPeriod.month,
        now: DateTime.utc(2026, 5, 26),
        fuels: const [],
        expenses: const [],
      );
      expect(r.totalSpent, Decimal.zero);
      expect(r.fuelSpent, Decimal.zero);
      expect(r.expensesSpent, Decimal.zero);
      expect(r.kmDriven, 0);
      expect(r.fuelEntriesCount, 0);
      expect(r.expensesCount, 0);
      expect(r.avgConsumptionKmL, isNull);
      expect(r.cheapestPricePerLiter, isNull);
      expect(r.mostExpensivePricePerLiter, isNull);
      expect(r.favoriteStation, isNull);
      expect(r.topExpenseCategory, isNull);
    });

    test('semanal cobre últimos 7 dias', () {
      final now = DateTime.utc(2026, 5, 26);
      final r = computeRecap(
        period: RecapPeriod.week,
        now: now,
        fuels: [
          _f(id: 'in', odometer: 100, liters: '40', price: '5',
              date: now.subtract(const Duration(days: 3))),
          _f(id: 'out', odometer: 100, liters: '40', price: '5',
              date: now.subtract(const Duration(days: 10))),
        ],
        expenses: const [],
      );
      expect(r.fuelEntriesCount, 1);
      expect(r.fuelSpent, Decimal.parse('200'));
    });

    test('mensal cobre mês corrente', () {
      final now = DateTime.utc(2026, 5, 26);
      final r = computeRecap(
        period: RecapPeriod.month,
        now: now,
        fuels: [
          _f(id: 'in', odometer: 100, liters: '40', price: '5',
              date: DateTime.utc(2026, 5, 5)),
          _f(id: 'out', odometer: 100, liters: '40', price: '5',
              date: DateTime.utc(2026, 4, 28)),
        ],
        expenses: [
          _x(id: 'e1', amount: '100',
              date: DateTime.utc(2026, 5, 20),
              category: ExpenseCategory.manutencao),
        ],
      );
      expect(r.fuelEntriesCount, 1);
      expect(r.expensesCount, 1);
      expect(r.totalSpent, Decimal.parse('300'));
    });

    test('totalSpent = fuelSpent + expensesSpent', () {
      final now = DateTime.utc(2026, 5, 26);
      final r = computeRecap(
        period: RecapPeriod.month,
        now: now,
        fuels: [
          _f(id: 'a', odometer: 100, liters: '40', price: '5',
              date: DateTime.utc(2026, 5, 10)),
        ],
        expenses: [
          _x(id: 'e1', amount: '50',
              date: DateTime.utc(2026, 5, 11)),
        ],
      );
      expect(r.fuelSpent, Decimal.parse('200'));
      expect(r.expensesSpent, Decimal.parse('50'));
      expect(r.totalSpent, Decimal.parse('250'));
    });

    test('avgConsumption: < 2 fuels → null', () {
      final r = computeRecap(
        period: RecapPeriod.month,
        now: DateTime.utc(2026, 5, 26),
        fuels: [
          _f(id: 'a', odometer: 100, liters: '40', price: '5',
              date: DateTime.utc(2026, 5, 10)),
        ],
        expenses: const [],
      );
      expect(r.avgConsumptionKmL, isNull);
    });

    test('avgConsumption: max-min odometer / total liters', () {
      final r = computeRecap(
        period: RecapPeriod.month,
        now: DateTime.utc(2026, 5, 26),
        fuels: [
          _f(id: 'a', odometer: 1000, liters: '40', price: '5',
              date: DateTime.utc(2026, 5, 5)),
          _f(id: 'b', odometer: 1500, liters: '40', price: '5',
              date: DateTime.utc(2026, 5, 20)),
        ],
        expenses: const [],
      );
      // (1500-1000) / (40+40) = 500/80 = 6.25 km/L
      expect(r.avgConsumptionKmL, Decimal.parse('6.25'));
      expect(r.kmDriven, 500);
    });

    test('cheapest/mostExpensive pricePerLiter', () {
      final r = computeRecap(
        period: RecapPeriod.month,
        now: DateTime.utc(2026, 5, 26),
        fuels: [
          _f(id: 'a', odometer: 100, liters: '40', price: '5.50',
              date: DateTime.utc(2026, 5, 5)),
          _f(id: 'b', odometer: 200, liters: '40', price: '5.99',
              date: DateTime.utc(2026, 5, 10)),
          _f(id: 'c', odometer: 300, liters: '40', price: '5.20',
              date: DateTime.utc(2026, 5, 15)),
        ],
        expenses: const [],
      );
      expect(r.cheapestPricePerLiter, Decimal.parse('5.20'));
      expect(r.mostExpensivePricePerLiter, Decimal.parse('5.99'));
    });

    test('topExpenseCategory: mais frequente', () {
      final r = computeRecap(
        period: RecapPeriod.month,
        now: DateTime.utc(2026, 5, 26),
        fuels: const [],
        expenses: [
          _x(id: 'a', amount: '100', date: DateTime.utc(2026, 5, 5),
              category: ExpenseCategory.lavagem),
          _x(id: 'b', amount: '200', date: DateTime.utc(2026, 5, 10),
              category: ExpenseCategory.manutencao),
          _x(id: 'c', amount: '300', date: DateTime.utc(2026, 5, 15),
              category: ExpenseCategory.manutencao),
        ],
      );
      expect(r.topExpenseCategory, isNotNull);
      expect(r.topExpenseCategory!.toLowerCase(),
          contains('manuten'));
    });

    test('favoriteStation: usa estação mais frequente', () {
      final r = computeRecap(
        period: RecapPeriod.month,
        now: DateTime.utc(2026, 5, 26),
        fuels: [
          _f(id: 'a', odometer: 100, liters: '40', price: '5',
              date: DateTime.utc(2026, 5, 5),
              brand: 'Shell', name: 'X'),
          _f(id: 'b', odometer: 200, liters: '40', price: '5',
              date: DateTime.utc(2026, 5, 10),
              brand: 'Shell', name: 'X'),
          _f(id: 'c', odometer: 300, liters: '40', price: '5',
              date: DateTime.utc(2026, 5, 15),
              brand: 'Petrobras', name: 'Y'),
        ],
        expenses: const [],
      );
      expect(r.favoriteStation, isNotNull);
      expect(r.favoriteStation!.contains('Shell'), isTrue);
    });

    test('datas fora do range ignoradas', () {
      final r = computeRecap(
        period: RecapPeriod.week,
        now: DateTime.utc(2026, 5, 26),
        fuels: [
          _f(id: 'old', odometer: 100, liters: '40', price: '5',
              date: DateTime.utc(2026, 1, 1)),
        ],
        expenses: [
          _x(id: 'old', amount: '500',
              date: DateTime.utc(2026, 1, 5)),
        ],
      );
      expect(r.totalSpent, Decimal.zero);
    });
  });
}
