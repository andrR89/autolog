import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/trips/trip_stats.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.X — função pura de agregação de viagem.
FuelEntry _f({
  required String id,
  required int odometer,
  required String liters,
  required String total,
  required DateTime date,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: odometer,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse(total),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.synced,
    );

Expense _x({
  required String id,
  required String amount,
  required DateTime date,
}) =>
    Expense(
      id: id,
      vehicleId: 'v1',
      date: date,
      category: ExpenseCategory.estacionamento,
      description: 'pedagio',
      amount: Decimal.parse(amount),
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.synced,
    );

void main() {
  group('computeTripStats', () {
    final start = DateTime.utc(2026, 5, 1);
    final end = DateTime.utc(2026, 5, 7);

    test('listas vazias → tudo zero, consumption null', () {
      final r = computeTripStats(
        start: start, end: end,
        fuels: const [], expenses: const [],
      );
      expect(r.fuelCount, 0);
      expect(r.expenseCount, 0);
      expect(r.totalSpent, Decimal.zero);
      expect(r.kmDriven, 0);
      expect(r.avgConsumptionKmL, isNull);
      expect(r.days, 7); // 7 a 1 + 1 inclusivo
    });

    test('agrega total = fuel + expense', () {
      final r = computeTripStats(
        start: start, end: end,
        fuels: [
          _f(id: 'a', odometer: 100, liters: '40', total: '200',
              date: DateTime.utc(2026, 5, 2)),
        ],
        expenses: [
          _x(id: 'x', amount: '50', date: DateTime.utc(2026, 5, 3)),
        ],
      );
      expect(r.fuelSpent, Decimal.parse('200'));
      expect(r.expensesSpent, Decimal.parse('50'));
      expect(r.totalSpent, Decimal.parse('250'));
    });

    test('km e consumo computados com 2+ fuels no range', () {
      final r = computeTripStats(
        start: start, end: end,
        fuels: [
          _f(id: 'a', odometer: 1000, liters: '40', total: '200',
              date: DateTime.utc(2026, 5, 1)),
          _f(id: 'b', odometer: 1500, liters: '40', total: '200',
              date: DateTime.utc(2026, 5, 6)),
        ],
        expenses: const [],
      );
      expect(r.kmDriven, 500);
      expect(r.avgConsumptionKmL, Decimal.parse('6.25')); // 500/80
    });

    test('entries fora do range são ignoradas', () {
      final r = computeTripStats(
        start: start, end: end,
        fuels: [
          _f(id: 'in', odometer: 100, liters: '40', total: '200',
              date: DateTime.utc(2026, 5, 3)),
          _f(id: 'out', odometer: 100, liters: '40', total: '200',
              date: DateTime.utc(2026, 4, 20)),
        ],
        expenses: [
          _x(id: 'in', amount: '100', date: DateTime.utc(2026, 5, 4)),
          _x(id: 'out', amount: '500', date: DateTime.utc(2026, 6, 1)),
        ],
      );
      expect(r.fuelCount, 1);
      expect(r.expenseCount, 1);
      expect(r.totalSpent, Decimal.parse('300'));
    });

    test('days inclui início E fim', () {
      final r = computeTripStats(
        start: DateTime.utc(2026, 5, 1),
        end: DateTime.utc(2026, 5, 1),
        fuels: const [], expenses: const [],
      );
      expect(r.days, 1);
    });

    test('1 fuel só → kmDriven=0, consumption=null', () {
      final r = computeTripStats(
        start: start, end: end,
        fuels: [
          _f(id: 'a', odometer: 1000, liters: '40', total: '200',
              date: DateTime.utc(2026, 5, 3)),
        ],
        expenses: const [],
      );
      expect(r.kmDriven, 0);
      expect(r.avgConsumptionKmL, isNull);
    });
  });
}
