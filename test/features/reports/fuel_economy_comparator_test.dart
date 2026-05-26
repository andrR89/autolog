import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/fuel_economy_comparator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.R — comparador etanol × gasolina.
/// Spec: docs/specs/sprint-6.R-etanol-vs-gasolina.md

FuelEntry _e({
  required String id,
  required int odometer,
  required String liters,
  required String price,
  required FuelType type,
  bool fullTank = true,
  DateTime? date,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: date ?? DateTime.utc(2026, 5, 1),
      odometer: odometer,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse(price),
      totalCost: Decimal.parse(liters) * Decimal.parse(price),
      fullTank: fullTank,
      fuelType: type,
      source: FuelSource.manual,
      createdAt: date ?? DateTime.utc(2026, 5, 1),
      updatedAt: date ?? DateTime.utc(2026, 5, 1),
      syncStatus: SyncStatus.synced,
    );

void main() {
  group('computeFuelEconomy', () {
    test('lista vazia → null', () {
      expect(computeFuelEconomy(const [], FuelType.gasolina), isNull);
    });

    test('1 abastecimento → null (precisa baseline)', () {
      final r = computeFuelEconomy([
        _e(id: 'a', odometer: 1000, liters: '40', price: '5', type: FuelType.gasolina),
      ], FuelType.gasolina);
      expect(r, isNull);
    });

    test('2 cheios consecutivos do mesmo tipo → km/L correto', () {
      // Carro andou 500 km usando 40 L → 12.5 km/L
      final r = computeFuelEconomy([
        _e(id: 'a', odometer: 1000, liters: '40', price: '5',
            type: FuelType.gasolina, date: DateTime.utc(2026, 4, 1)),
        _e(id: 'b', odometer: 1500, liters: '40', price: '5',
            type: FuelType.gasolina, date: DateTime.utc(2026, 4, 15)),
      ], FuelType.gasolina);
      expect(r, isNotNull);
      expect(r!.kmPerLiter, Decimal.parse('12.5'));
      expect(r.basedOnEntries, 2);
    });

    test('alternando tipos (flex) → considera só os do tipo solicitado', () {
      final entries = [
        _e(id: 'g1', odometer: 1000, liters: '40', price: '5',
            type: FuelType.gasolina, date: DateTime.utc(2026, 4, 1)),
        _e(id: 'e1', odometer: 1400, liters: '50', price: '3.5',
            type: FuelType.etanol, date: DateTime.utc(2026, 4, 10)),
        _e(id: 'g2', odometer: 1880, liters: '40', price: '5',
            type: FuelType.gasolina, date: DateTime.utc(2026, 4, 20)),
        _e(id: 'e2', odometer: 2280, liters: '50', price: '3.5',
            type: FuelType.etanol, date: DateTime.utc(2026, 5, 1)),
      ];
      // Pra gasolina: 1000→1880, mas tem etanol no meio. Cheio→cheio do tipo:
      // (1880-1000)/40 = 22 (irrealista, mas o cálculo deve usar isso)
      final g = computeFuelEconomy(entries, FuelType.gasolina);
      expect(g, isNotNull);

      // Pra etanol: 1400→2280 = 880 / 50 = 17.6 km/L
      final e = computeFuelEconomy(entries, FuelType.etanol);
      expect(e, isNotNull);
      expect(e!.kmPerLiter, Decimal.parse('17.6'));
    });
  });

  group('lastPriceFor', () {
    test('sem entries → null', () {
      expect(lastPriceFor(const [], FuelType.gasolina), isNull);
    });

    test('última entry do tipo retorna preço dela', () {
      final r = lastPriceFor([
        _e(id: 'a', odometer: 0, liters: '40', price: '5.50',
            type: FuelType.gasolina, date: DateTime.utc(2026, 4, 1)),
        _e(id: 'b', odometer: 100, liters: '40', price: '5.99',
            type: FuelType.gasolina, date: DateTime.utc(2026, 5, 1)),
        _e(id: 'c', odometer: 200, liters: '50', price: '3.49',
            type: FuelType.etanol, date: DateTime.utc(2026, 5, 15)),
      ], FuelType.gasolina);
      expect(r, Decimal.parse('5.99'));
    });

    test('sem entry do tipo → null', () {
      final r = lastPriceFor([
        _e(id: 'a', odometer: 0, liters: '50', price: '3.5',
            type: FuelType.etanol),
      ], FuelType.gasolina);
      expect(r, isNull);
    });
  });

  group('compareFuels', () {
    test('sem histórico → usa fallback genérico (gas 12, et 8.4 km/L)', () {
      final r = compareFuels(
        gasolinaPricePerLiter: Decimal.parse('5.99'),
        etanolPricePerLiter: Decimal.parse('3.99'),
        historicalEntries: const [],
      );
      // gasolina: 5.99 / 12 = 0.4992 ≈ 0.4992
      // etanol: 3.99 / 8.4 = 0.475 ≈ 0.475
      // etanol mais barato por km
      expect(r.bestChoice, FuelType.etanol);
      expect(r.savingsPercent > Decimal.zero, isTrue);
    });

    test(r'etanol mais barato em R$/km → bestChoice etanol', () {
      // Veículo com mesmo consumo: gasolina cara, etanol barato
      final entries = [
        _e(id: 'g1', odometer: 0, liters: '40', price: '5',
            type: FuelType.gasolina, date: DateTime.utc(2026, 4, 1)),
        _e(id: 'g2', odometer: 400, liters: '40', price: '5',
            type: FuelType.gasolina, date: DateTime.utc(2026, 4, 15)),
        _e(id: 'e1', odometer: 800, liters: '50', price: '3',
            type: FuelType.etanol, date: DateTime.utc(2026, 4, 25)),
        _e(id: 'e2', odometer: 1200, liters: '50', price: '3',
            type: FuelType.etanol, date: DateTime.utc(2026, 5, 5)),
      ];
      // gas: 10 km/L → 5/10 = R$0.50/km
      // et: 8 km/L → 3/8 = R$0.375/km
      final r = compareFuels(
        gasolinaPricePerLiter: Decimal.parse('5'),
        etanolPricePerLiter: Decimal.parse('3'),
        historicalEntries: entries,
      );
      expect(r.bestChoice, FuelType.etanol);
      expect(r.etanolCostPerKm < r.gasolinaCostPerKm, isTrue);
    });

    test(r'gasolina mais barata em R$/km → bestChoice gasolina', () {
      // Etanol caro relativo
      final r = compareFuels(
        gasolinaPricePerLiter: Decimal.parse('5'),
        etanolPricePerLiter: Decimal.parse('4.5'),
        historicalEntries: const [],
      );
      // gas: 5/12 = 0.4167
      // et: 4.5/8.4 = 0.5357
      // gasolina vence
      expect(r.bestChoice, FuelType.gasolina);
      expect(r.gasolinaCostPerKm < r.etanolCostPerKm, isTrue);
    });

    test('savingsPercent calculado corretamente', () {
      // Etanol metade do custo da gasolina
      final r = compareFuels(
        gasolinaPricePerLiter: Decimal.parse('12'), // 12/12 = 1.0/km
        etanolPricePerLiter: Decimal.parse('4.2'),  // 4.2/8.4 = 0.5/km
        historicalEntries: const [],
      );
      expect(r.bestChoice, FuelType.etanol);
      // savings = (1.0 - 0.5) / 1.0 * 100 = 50%
      expect(r.savingsPercent, Decimal.parse('50'));
    });
  });
}
