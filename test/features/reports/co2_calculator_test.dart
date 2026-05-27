import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/reports/co2_calculator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.DD — CO2 calculator puro.
FuelEntry _f({
  required String id,
  required String liters,
  required FuelType type,
}) =>
    FuelEntry(
      id: id,
      vehicleId: 'v1',
      date: DateTime.utc(2026, 5, 10),
      odometer: 100,
      liters: Decimal.parse(liters),
      pricePerLiter: Decimal.parse('5'),
      totalCost: Decimal.parse(liters) * Decimal.parse('5'),
      fullTank: true,
      fuelType: type,
      source: FuelSource.manual,
      createdAt: DateTime.utc(2026, 5, 10),
      updatedAt: DateTime.utc(2026, 5, 10),
      syncStatus: SyncStatus.synced,
    );

void main() {
  group('kgCo2PerLiter', () {
    test('valores por tipo', () {
      expect(kgCo2PerLiter(FuelType.gasolina), Decimal.parse('2.31'));
      expect(kgCo2PerLiter(FuelType.etanol), Decimal.parse('1.51'));
      expect(kgCo2PerLiter(FuelType.diesel), Decimal.parse('2.68'));
      expect(kgCo2PerLiter(FuelType.gnv), Decimal.parse('1.93'));
      // flex: usa gasolina como conservador quando não tem contexto.
      expect(kgCo2PerLiter(FuelType.flex), Decimal.parse('2.31'));
    });
  });

  group('computeCo2', () {
    test('lista vazia → 0 kg, 0 árvores', () {
      final r = computeCo2(entries: const []);
      expect(r.totalKg, Decimal.zero);
      expect(r.treesEquivalentYear, 0);
    });

    test('1 entry gasolina 40L → 40*2.31 = 92.4 kg', () {
      final r = computeCo2(
        entries: [_f(id: 'a', liters: '40', type: FuelType.gasolina)],
      );
      expect(r.totalKg, Decimal.parse('92.40'));
      expect(r.treesEquivalentYear, 4); // floor(92.4/22)
    });

    test('mix tipos soma corretamente', () {
      // 40L gasolina (92.4) + 50L etanol (75.5) = 167.9
      final r = computeCo2(
        entries: [
          _f(id: 'g', liters: '40', type: FuelType.gasolina),
          _f(id: 'e', liters: '50', type: FuelType.etanol),
        ],
      );
      expect(r.totalKg, Decimal.parse('167.90'));
      expect(r.treesEquivalentYear, 7); // floor(167.9/22) = 7
    });

    test('precisão decimal preservada (não vira double)', () {
      // 43.219L gasolina = 43.219 * 2.31 = 99.83589
      final r = computeCo2(
        entries: [_f(id: 'a', liters: '43.219', type: FuelType.gasolina)],
      );
      expect(r.totalKg, Decimal.parse('99.83589'));
    });
  });
}
