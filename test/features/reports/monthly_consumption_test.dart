import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/monthly_consumption.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 5.2 — consumo médio (km/l) por mês, ponderado por km.
/// Spec: docs/specs/sprint-5.2-monthly-consumption.md
void main() {
  FuelEntry entry({
    required String id,
    required DateTime date,
    required int odometer,
    required String liters,
    required bool fullTank,
  }) {
    return FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date,
      odometer: odometer,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse('200'),
      fullTank: fullTank,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  group('computeMonthlyConsumption', () {
    test('lista vazia → vazio', () {
      expect(computeMonthlyConsumption(const []), isEmpty);
    });

    test('único entry: sem ciclo fechado, vazio', () {
      expect(
        computeMonthlyConsumption([
          entry(
            id: 'e1',
            date: DateTime.utc(2026, 5, 15),
            odometer: 10000,
            liters: '0',
            fullTank: true,
          ),
        ]),
        isEmpty,
      );
    });

    test('dois cheios no mesmo mês: bucket único com km/l', () {
      final r = computeMonthlyConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 15),
          odometer: 10000,
          liters: '0',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 25),
          odometer: 10500,
          liters: '40',
          fullTank: true,
        ),
      ]);
      expect(r, hasLength(1));
      expect(r.first.month, DateTime.utc(2026, 5, 1));
      expect(r.first.kmPerLiter, Decimal.parse('12.5000'));
    });

    test('ciclo abre num mês, fecha em outro: bucket é mês de fechamento', () {
      final r = computeMonthlyConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 4, 28),
          odometer: 10000,
          liters: '0',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 10),
          odometer: 10500,
          liters: '40',
          fullTank: true,
        ),
      ]);
      expect(r, hasLength(1));
      expect(r.first.month, DateTime.utc(2026, 5, 1));
      expect(r.first.kmPerLiter, Decimal.parse('12.5000'));
    });

    test('múltiplos ciclos no mesmo mês: ponderação por km', () {
      // ciclo1: 500km / 40L; ciclo2: 500km / 50L → bucket maio = 1000/90 = 11,1111
      final r = computeMonthlyConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '0',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 10),
          odometer: 10500,
          liters: '40',
          fullTank: true,
        ),
        entry(
          id: 'e3',
          date: DateTime.utc(2026, 5, 20),
          odometer: 11000,
          liters: '50',
          fullTank: true,
        ),
      ]);
      expect(r, hasLength(1));
      expect(r.first.kmPerLiter, Decimal.parse('11.1111'));
    });

    test('múltiplos meses: buckets separados, ordem ASC', () {
      // Maio: ciclo 500/40 = 12,5. Junho: ciclo 400/40 = 10,0.
      final r = computeMonthlyConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '0',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 20),
          odometer: 10500,
          liters: '40',
          fullTank: true,
        ),
        entry(
          id: 'e3',
          date: DateTime.utc(2026, 6, 10),
          odometer: 10900,
          liters: '40',
          fullTank: true,
        ),
      ]);
      expect(r, hasLength(2));
      expect(r[0].month, DateTime.utc(2026, 5, 1));
      expect(r[0].kmPerLiter, Decimal.parse('12.5000'));
      expect(r[1].month, DateTime.utc(2026, 6, 1));
      expect(r[1].kmPerLiter, Decimal.parse('10.0000'));
    });

    test('precisão decimal exata', () {
      // 250/22.5 = 11.111... → 11,1111
      final r = computeMonthlyConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '0',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 10),
          odometer: 10250,
          liters: '22.5',
          fullTank: true,
        ),
      ]);
      expect(r.first.kmPerLiter, Decimal.parse('11.1111'));
    });

    test('ciclo com km <= 0 (odômetro regrediu) é ignorado', () {
      // e1@10000, e2@9500 cheio → km negativo, ciclo ignorado. Maio fica vazio.
      // Mas e2 vira novo baseline; e3@10000 com 40L → km = 500, ciclo válido em junho.
      final r = computeMonthlyConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '0',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 10),
          odometer: 9500,
          liters: '20',
          fullTank: true,
        ),
        entry(
          id: 'e3',
          date: DateTime.utc(2026, 6, 1),
          odometer: 10000,
          liters: '40',
          fullTank: true,
        ),
      ]);
      // Maio: ciclo e1→e2 inválido (km<0), skip. Junho: ciclo e2→e3, 500/40 = 12,5.
      expect(r, hasLength(1));
      expect(r.first.month, DateTime.utc(2026, 6, 1));
      expect(r.first.kmPerLiter, Decimal.parse('12.5000'));
    });
  });
}
