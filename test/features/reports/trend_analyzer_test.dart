import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/trend_analyzer.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.Q — análise de tendência.
/// Spec: docs/specs/sprint-6.Q-cost-per-km-trend.md

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
      category: ExpenseCategory.manutencao,
      description: 'X',
      amount: Decimal.parse(amount),
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.synced,
    );

void main() {
  final now = DateTime.utc(2026, 5, 26);

  group('analyzeConsumptionTrend', () {
    test('listas vazias → hasEnoughData=false', () {
      final r = analyzeConsumptionTrend(entries: const [], now: now);
      expect(r.hasEnoughData, isFalse);
    });

    test('1 entrada em cada janela → hasEnoughData=false', () {
      final r = analyzeConsumptionTrend(
        entries: [
          _f(id: 'a', odometer: 0, liters: '40', total: '200',
              date: now.subtract(const Duration(days: 60))),
          _f(id: 'b', odometer: 0, liters: '40', total: '200',
              date: now.subtract(const Duration(days: 150))),
        ],
        now: now,
      );
      expect(r.hasEnoughData, isFalse);
    });

    test('consumo melhora (sobe km/L) → direction.up, delta positivo', () {
      // Atual: 12 km/L. Anterior: 10 km/L. Delta +20%.
      final r = analyzeConsumptionTrend(
        entries: [
          // Janela anterior (180-90 dias atrás): consumo ~10 km/L
          _f(id: 'p1', odometer: 0, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 500, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 130))),
          // Janela atual (0-90 dias atrás): consumo ~12 km/L
          _f(id: 'c1', odometer: 5000, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5600, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 30))),
        ],
        now: now,
      );
      expect(r.hasEnoughData, isTrue);
      expect(r.direction, TrendDirection.up);
      expect(r.deltaPercent > Decimal.zero, isTrue);
    });

    test('consumo piora (cai km/L) → direction.down, delta negativo', () {
      final r = analyzeConsumptionTrend(
        entries: [
          // Anterior: 12 km/L
          _f(id: 'p1', odometer: 0, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 600, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 130))),
          // Atual: 10 km/L
          _f(id: 'c1', odometer: 5000, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5500, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 30))),
        ],
        now: now,
      );
      expect(r.hasEnoughData, isTrue);
      expect(r.direction, TrendDirection.down);
      expect(r.deltaPercent < Decimal.zero, isTrue);
    });

    test('variação <= threshold default (5%) → stable', () {
      // Anterior: 10 km/L; atual: 10.3 km/L → +3%
      final r = analyzeConsumptionTrend(
        entries: [
          _f(id: 'p1', odometer: 0, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 170))),
          _f(id: 'p2', odometer: 500, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 130))),
          _f(id: 'c1', odometer: 5000, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 70))),
          _f(id: 'c2', odometer: 5515, liters: '50', total: '250',
              date: now.subtract(const Duration(days: 30))),
        ],
        now: now,
      );
      expect(r.direction, TrendDirection.stable);
    });
  });

  group('analyzeSpendingTrend', () {
    test('gasto sobe → up', () {
      final r = analyzeSpendingTrend(
        fuels: [
          _f(id: 'p', odometer: 0, liters: '40', total: '200',
              date: now.subtract(const Duration(days: 150))),
        ],
        expenses: [
          _x(id: 'xp', amount: '100',
              date: now.subtract(const Duration(days: 150))),
          _x(id: 'xc', amount: '500',
              date: now.subtract(const Duration(days: 30))),
        ],
        now: now,
      );
      expect(r.direction, TrendDirection.up);
    });

    test('gasto cai → down', () {
      final r = analyzeSpendingTrend(
        fuels: const [],
        expenses: [
          _x(id: 'xp', amount: '500',
              date: now.subtract(const Duration(days: 150))),
          _x(id: 'xc', amount: '100',
              date: now.subtract(const Duration(days: 30))),
        ],
        now: now,
      );
      expect(r.direction, TrendDirection.down);
    });

    test('datas fora da janela ignoradas', () {
      // Tudo fora das janelas (>180 dias atrás)
      final r = analyzeSpendingTrend(
        fuels: const [],
        expenses: [
          _x(id: 'old', amount: '500',
              date: now.subtract(const Duration(days: 500))),
        ],
        now: now,
      );
      expect(r.hasEnoughData, isFalse);
    });
  });
}
