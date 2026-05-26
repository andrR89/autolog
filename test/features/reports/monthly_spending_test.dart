import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/monthly_spending.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 5.1 — agregação gasto/mês (fuel + expenses).
/// Spec: docs/specs/sprint-5.1-monthly-spending.md
void main() {
  FuelEntry fuel({
    required String id,
    required DateTime date,
    required String totalCost,
  }) {
    return FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: 10000,
      liters: Decimal.parse('40'),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse(totalCost),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  Expense expense({
    required String id,
    required DateTime date,
    required String amount,
  }) {
    return Expense(
      id: id,
      vehicleId: 'v1',
      date: date,
      category: ExpenseCategory.manutencao,
      description: 'X',
      amount: Decimal.parse(amount),
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  group('computeMonthlySpending', () {
    test('listas vazias → vazio', () {
      expect(
        computeMonthlySpending(fuelEntries: const [], expenses: const []),
        isEmpty,
      );
    });

    test('só fuel, mesmo mês: soma no bucket único', () {
      final r = computeMonthlySpending(
        fuelEntries: [
          fuel(id: 'f1', date: DateTime.utc(2026, 5, 10), totalCost: '200'),
          fuel(id: 'f2', date: DateTime.utc(2026, 5, 22), totalCost: '150'),
        ],
        expenses: const [],
      );
      expect(r, hasLength(1));
      expect(r.first.month, DateTime.utc(2026, 5, 1));
      expect(r.first.total, Decimal.parse('350'));
    });

    test('só expenses, mesmo mês: soma no bucket único', () {
      final r = computeMonthlySpending(
        fuelEntries: const [],
        expenses: [
          expense(id: 'e1', date: DateTime.utc(2026, 6, 5), amount: '100'),
          expense(id: 'e2', date: DateTime.utc(2026, 6, 20), amount: '50'),
        ],
      );
      expect(r, hasLength(1));
      expect(r.first.month, DateTime.utc(2026, 6, 1));
      expect(r.first.total, Decimal.parse('150'));
    });

    test('fuel + expenses no mesmo mês: soma combinada', () {
      final r = computeMonthlySpending(
        fuelEntries: [
          fuel(id: 'f1', date: DateTime.utc(2026, 7, 1), totalCost: '200'),
        ],
        expenses: [
          expense(id: 'e1', date: DateTime.utc(2026, 7, 15), amount: '100'),
        ],
      );
      expect(r, hasLength(1));
      expect(r.first.month, DateTime.utc(2026, 7, 1));
      expect(r.first.total, Decimal.parse('300'));
    });

    test('meses diferentes: buckets separados, ordem ASC', () {
      final r = computeMonthlySpending(
        fuelEntries: [
          fuel(id: 'f1', date: DateTime.utc(2026, 5, 10), totalCost: '200'),
        ],
        expenses: [
          expense(id: 'e1', date: DateTime.utc(2026, 7, 1), amount: '100'),
        ],
      );
      expect(r, hasLength(2));
      expect(r[0].month, DateTime.utc(2026, 5, 1));
      expect(r[0].total, Decimal.parse('200'));
      expect(r[1].month, DateTime.utc(2026, 7, 1));
      expect(r[1].total, Decimal.parse('100'));
    });

    test('precisão decimal exata na soma', () {
      final r = computeMonthlySpending(
        fuelEntries: [
          fuel(id: 'f1', date: DateTime.utc(2026, 5, 5), totalCost: '123.45'),
        ],
        expenses: [
          expense(id: 'e1', date: DateTime.utc(2026, 5, 15), amount: '67.89'),
        ],
      );
      expect(r.first.total, Decimal.parse('191.34'));
    });

    test('input desordenado: output ainda em ordem ASC por mês', () {
      final r = computeMonthlySpending(
        fuelEntries: [
          fuel(id: 'f1', date: DateTime.utc(2026, 8, 1), totalCost: '300'),
          fuel(id: 'f2', date: DateTime.utc(2026, 3, 1), totalCost: '100'),
          fuel(id: 'f3', date: DateTime.utc(2026, 5, 1), totalCost: '200'),
        ],
        expenses: const [],
      );
      expect(r.map((m) => m.month), [
        DateTime.utc(2026, 3, 1),
        DateTime.utc(2026, 5, 1),
        DateTime.utc(2026, 8, 1),
      ]);
    });

    test('bucket é UTC dia 1, independente de hora/dia da entry', () {
      final r = computeMonthlySpending(
        fuelEntries: [
          fuel(
            id: 'f1',
            date: DateTime.utc(2026, 5, 23, 14, 30, 45),
            totalCost: '100',
          ),
        ],
        expenses: const [],
      );
      expect(r.first.month, DateTime.utc(2026, 5, 1));
    });
  });
}
