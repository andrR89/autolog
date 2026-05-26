import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/services/consumption_calculator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 2.2 — Cálculo de consumo (regra de ouro #2).
/// Spec: docs/specs/sprint-2.2-consumption-calculator.md
/// Fonte: PRD §7.
void main() {
  Decimal d(String s) => Decimal.parse(s);

  FuelEntry entry({
    required String id,
    required DateTime date,
    required int odometer,
    required String liters,
    required String pricePerLiter,
    required String totalCost,
    required bool fullTank,
    String vehicleId = 'v1',
  }) {
    return FuelEntry(
      id: id,
      vehicleId: vehicleId,
      date: date,
      odometer: odometer,
      liters: d(liters),
      pricePerLiter: d(pricePerLiter),
      totalCost: d(totalCost),
      fullTank: fullTank,
      fuelType: FuelType.gasolina,
      source: FuelSource.manual,
      createdAt: date,
      updatedAt: date,
      syncStatus: SyncStatus.pending,
    );
  }

  group('computeConsumption — casos básicos', () {
    test('lista vazia retorna vazio', () {
      expect(computeConsumption([]), isEmpty);
    });

    test('único registro retorna kmPerLiter e costPerKm nulos', () {
      final e = entry(
        id: 'e1',
        date: DateTime.utc(2026, 5, 1),
        odometer: 10000,
        liters: '40',
        pricePerLiter: '5',
        totalCost: '200',
        fullTank: true,
      );
      final result = computeConsumption([e]);
      expect(result, hasLength(1));
      expect(result[0].entry, e);
      expect(result[0].kmPerLiter, isNull);
      expect(result[0].costPerKm, isNull);
    });

    test('dois cheios consecutivos: km/l e custo/km no segundo', () {
      final e1 = entry(
        id: 'e1',
        date: DateTime.utc(2026, 5, 1),
        odometer: 10000,
        liters: '40',
        pricePerLiter: '5',
        totalCost: '200',
        fullTank: true,
      );
      final e2 = entry(
        id: 'e2',
        date: DateTime.utc(2026, 5, 10),
        odometer: 10500,
        liters: '40',
        pricePerLiter: '5.5',
        totalCost: '220',
        fullTank: true,
      );
      final r = computeConsumption([e1, e2]);
      expect(r[0].kmPerLiter, isNull);
      expect(r[0].costPerKm, isNull);
      expect(r[1].kmPerLiter, d('12.5000'));
      expect(r[1].costPerKm, d('0.4400'));
    });
  });

  group('computeConsumption — janelas com parciais (PRD §7)', () {
    test('cheio → parcial → cheio: soma litros e custos da janela', () {
      final e1 = entry(
        id: 'e1',
        date: DateTime.utc(2026, 5, 1),
        odometer: 10000,
        liters: '40',
        pricePerLiter: '5',
        totalCost: '200',
        fullTank: true,
      );
      final e2 = entry(
        id: 'e2',
        date: DateTime.utc(2026, 5, 5),
        odometer: 10200,
        liters: '20',
        pricePerLiter: '5.5',
        totalCost: '110',
        fullTank: false,
      );
      final e3 = entry(
        id: 'e3',
        date: DateTime.utc(2026, 5, 10),
        odometer: 10500,
        liters: '30',
        pricePerLiter: '5.5',
        totalCost: '165',
        fullTank: true,
      );
      final r = computeConsumption([e1, e2, e3]);
      expect(r[0].kmPerLiter, isNull); // primeiro cheio, sem baseline
      expect(r[1].kmPerLiter, isNull); // parcial não fecha
      expect(r[1].costPerKm, isNull);
      // Janela e2+e3: km = 500, litros = 50, custo = 275.
      expect(r[2].kmPerLiter, d('10.0000'));
      expect(r[2].costPerKm, d('0.5500'));
    });

    test('múltiplos parciais entre dois cheios', () {
      final entries = [
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '40',
          pricePerLiter: '5',
          totalCost: '200',
          fullTank: true,
        ),
        entry(
          id: 'p1',
          date: DateTime.utc(2026, 5, 3),
          odometer: 10100,
          liters: '10',
          pricePerLiter: '5',
          totalCost: '50',
          fullTank: false,
        ),
        entry(
          id: 'p2',
          date: DateTime.utc(2026, 5, 5),
          odometer: 10250,
          liters: '15',
          pricePerLiter: '5',
          totalCost: '75',
          fullTank: false,
        ),
        entry(
          id: 'e4',
          date: DateTime.utc(2026, 5, 10),
          odometer: 10500,
          liters: '25',
          pricePerLiter: '5',
          totalCost: '125',
          fullTank: true,
        ),
      ];
      final r = computeConsumption(entries);
      expect(r[0].kmPerLiter, isNull);
      expect(r[1].kmPerLiter, isNull);
      expect(r[2].kmPerLiter, isNull);
      // Janela p1+p2+e4: km = 500, litros = 50, custo = 250 → km/l=10, custo/km=0.5.
      expect(r[3].kmPerLiter, d('10.0000'));
      expect(r[3].costPerKm, d('0.5000'));
    });

    test('três cheios em sequência calculam cada um sobre o anterior', () {
      final r = computeConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '40',
          pricePerLiter: '5',
          totalCost: '200',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 5),
          odometer: 10400,
          liters: '40',
          pricePerLiter: '5',
          totalCost: '200',
          fullTank: true,
        ),
        entry(
          id: 'e3',
          date: DateTime.utc(2026, 5, 10),
          odometer: 10800,
          liters: '50',
          pricePerLiter: '5',
          totalCost: '250',
          fullTank: true,
        ),
      ]);
      expect(r[0].kmPerLiter, isNull);
      expect(r[1].kmPerLiter, d('10.0000')); // 400 / 40
      expect(r[2].kmPerLiter, d('8.0000')); // 400 / 50
    });

    test('parcial antes do primeiro cheio: ambos sem baseline', () {
      final r = computeConsumption([
        entry(
          id: 'p1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '20',
          pricePerLiter: '5',
          totalCost: '100',
          fullTank: false,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 5),
          odometer: 10300,
          liters: '30',
          pricePerLiter: '5',
          totalCost: '150',
          fullTank: true,
        ),
        entry(
          id: 'e3',
          date: DateTime.utc(2026, 5, 10),
          odometer: 10700,
          liters: '40',
          pricePerLiter: '5',
          totalCost: '200',
          fullTank: true,
        ),
      ]);
      expect(r[0].kmPerLiter, isNull); // parcial
      expect(r[1].kmPerLiter, isNull); // primeiro cheio
      expect(r[2].kmPerLiter, d('10.0000')); // 400 / 40
    });
  });

  group('computeConsumption — defensivo (NUNCA exibir número errado)', () {
    test('odômetro regrediu: não calcula nem lança', () {
      final r = computeConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '40',
          pricePerLiter: '5',
          totalCost: '200',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 5),
          odometer: 9500,
          liters: '40',
          pricePerLiter: '5',
          totalCost: '200',
          fullTank: true,
        ),
      ]);
      expect(r[1].kmPerLiter, isNull);
      expect(r[1].costPerKm, isNull);
    });

    test('litros zero (defensivo): retorna null sem dividir por zero', () {
      final r = computeConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '40',
          pricePerLiter: '5',
          totalCost: '200',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 5),
          odometer: 10500,
          liters: '0',
          pricePerLiter: '0',
          totalCost: '0',
          fullTank: true,
        ),
      ]);
      expect(r[1].kmPerLiter, isNull);
    });
  });

  group('computeConsumption — precisão decimal e ordem', () {
    test('precisão decimal exata, sem double, escala 4', () {
      final r = computeConsumption([
        entry(
          id: 'e1',
          date: DateTime.utc(2026, 5, 1),
          odometer: 10000,
          liters: '30',
          pricePerLiter: '5.833',
          totalCost: '174.99',
          fullTank: true,
        ),
        entry(
          id: 'e2',
          date: DateTime.utc(2026, 5, 10),
          odometer: 10250,
          liters: '22.5',
          pricePerLiter: '5.799',
          totalCost: '130.49',
          fullTank: true,
        ),
      ]);
      // 250 / 22.5 = 11.1111... → escala 4 half-even = 11.1111
      expect(r[1].kmPerLiter, d('11.1111'));
      // 130.49 / 250 = 0.52196 → escala 4 half-even = 0.5220
      expect(r[1].costPerKm, d('0.5220'));
    });

    test('ordem da lista é preservada', () {
      final e1 = entry(
        id: 'e1',
        date: DateTime.utc(2026, 5, 1),
        odometer: 10000,
        liters: '40',
        pricePerLiter: '5',
        totalCost: '200',
        fullTank: true,
      );
      final e2 = entry(
        id: 'e2',
        date: DateTime.utc(2026, 5, 5),
        odometer: 10400,
        liters: '40',
        pricePerLiter: '5',
        totalCost: '200',
        fullTank: true,
      );
      final r = computeConsumption([e1, e2]);
      expect(r.map((c) => c.entry.id), ['e1', 'e2']);
    });
  });

  group('isOdometerMonotonic', () {
    test('previous null sempre true', () {
      expect(isOdometerMonotonic(candidate: 0, previous: null), isTrue);
      expect(isOdometerMonotonic(candidate: 99999, previous: null), isTrue);
    });

    test('candidate >= previous é true; menor é false', () {
      expect(isOdometerMonotonic(candidate: 101, previous: 100), isTrue);
      expect(isOdometerMonotonic(candidate: 100, previous: 100), isTrue);
      expect(isOdometerMonotonic(candidate: 99, previous: 100), isFalse);
    });
  });
}
