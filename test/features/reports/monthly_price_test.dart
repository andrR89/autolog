import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/monthly_price.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 5.3 — evolução do preço/litro mensal, ponderado por litros.
/// Spec: docs/specs/sprint-5.3-monthly-price.md
void main() {
  FuelEntry fuel({
    required String id,
    required DateTime date,
    required String liters,
    required String totalCost,
  }) {
    return FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: 10000,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse('5'), // ignorado pelo cálculo
      totalCost: Decimal.parse(totalCost),
      fullTank: true,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  group('computeMonthlyPrice', () {
    test('lista vazia → vazio', () {
      expect(computeMonthlyPrice(const []), isEmpty);
    });

    test('um fuel no mês: preço/L = totalCost/liters', () {
      final r = computeMonthlyPrice([
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 5, 10),
          liters: '40',
          totalCost: '200',
        ),
      ]);
      expect(r, hasLength(1));
      expect(r.first.month, DateTime.utc(2026, 5, 1));
      expect(r.first.pricePerLiter, Decimal.parse('5.0000'));
    });

    test(
      'múltiplos fuels no mês: ponderado por litros (não média aritmética)',
      () {
        // E1: 10L × R$5 = R$50; E2: 40L × R$6 = R$240. Total: 50L, R$290.
        // Ponderado: 290/50 = 5,80. Média aritmética seria (5+6)/2 = 5,50.
        final r = computeMonthlyPrice([
          fuel(
            id: 'f1',
            date: DateTime.utc(2026, 5, 5),
            liters: '10',
            totalCost: '50',
          ),
          fuel(
            id: 'f2',
            date: DateTime.utc(2026, 5, 15),
            liters: '40',
            totalCost: '240',
          ),
        ]);
        expect(r, hasLength(1));
        expect(r.first.pricePerLiter, Decimal.parse('5.8000'));
      },
    );

    test('múltiplos meses: buckets separados ordenados ASC', () {
      final r = computeMonthlyPrice([
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 5, 10),
          liters: '40',
          totalCost: '200',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 6, 10),
          liters: '40',
          totalCost: '240',
        ),
      ]);
      expect(r, hasLength(2));
      expect(r[0].month, DateTime.utc(2026, 5, 1));
      expect(r[0].pricePerLiter, Decimal.parse('5.0000'));
      expect(r[1].month, DateTime.utc(2026, 6, 1));
      expect(r[1].pricePerLiter, Decimal.parse('6.0000'));
    });

    test('precisão decimal: 100/3 → 33,3333 (4 casas, half-up)', () {
      final r = computeMonthlyPrice([
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 5, 1),
          liters: '3',
          totalCost: '100',
        ),
      ]);
      expect(r.first.pricePerLiter, Decimal.parse('33.3333'));
    });

    test('mês com TODOS liters=0 é pulado (defensivo)', () {
      final r = computeMonthlyPrice([
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 5, 5),
          liters: '0',
          totalCost: '0',
        ),
      ]);
      expect(r, isEmpty);
    });

    test('input desordenado: output em ordem ASC por mês', () {
      final r = computeMonthlyPrice([
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 8, 1),
          liters: '40',
          totalCost: '240',
        ),
        fuel(
          id: 'f2',
          date: DateTime.utc(2026, 3, 1),
          liters: '40',
          totalCost: '200',
        ),
        fuel(
          id: 'f3',
          date: DateTime.utc(2026, 5, 1),
          liters: '40',
          totalCost: '220',
        ),
      ]);
      expect(r.map((m) => m.month), [
        DateTime.utc(2026, 3, 1),
        DateTime.utc(2026, 5, 1),
        DateTime.utc(2026, 8, 1),
      ]);
    });

    test('bucket UTC dia 1, independente de hora/dia da entry', () {
      final r = computeMonthlyPrice([
        fuel(
          id: 'f1',
          date: DateTime.utc(2026, 5, 23, 14, 30, 45),
          liters: '40',
          totalCost: '200',
        ),
      ]);
      expect(r.first.month, DateTime.utc(2026, 5, 1));
    });
  });
}
