import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/fuel/fuel_form_validators.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Patch 2.3 — fuel form: combustível contextual + cálculo flexível 2→1.
/// Spec: docs/specs/sprint-2.3-patch-fuel-context-and-flex-calc.md
void main() {
  group('availableFuelTypesFor', () {
    test('gasolina → [gasolina]', () {
      expect(availableFuelTypesFor(FuelType.gasolina), [FuelType.gasolina]);
    });
    test('etanol → [etanol]', () {
      expect(availableFuelTypesFor(FuelType.etanol), [FuelType.etanol]);
    });
    test('diesel → [diesel]', () {
      expect(availableFuelTypesFor(FuelType.diesel), [FuelType.diesel]);
    });
    test('flex → [gasolina, etanol] (no abastecimento real escolhe um dos 2)',
        () {
      expect(availableFuelTypesFor(FuelType.flex), [
        FuelType.gasolina,
        FuelType.etanol,
      ]);
    });
    test('gnv → [gnv]', () {
      expect(availableFuelTypesFor(FuelType.gnv), [FuelType.gnv]);
    });
  });

  group('computeMissingTriplet', () {
    test(
      '2 presentes (liters+price), sem total → total = liters × price exato',
      () {
        final r = computeMissingTriplet(
          FuelTriplet(
            liters: Decimal.parse('40'),
            pricePerLiter: Decimal.parse('5'),
          ),
        );
        expect(r.liters, Decimal.parse('40'));
        expect(r.pricePerLiter, Decimal.parse('5'));
        expect(r.totalCost, Decimal.parse('200'));
      },
    );

    test('2 presentes (liters+total), sem price → price = total / liters', () {
      final r = computeMissingTriplet(
        FuelTriplet(
          liters: Decimal.parse('40'),
          totalCost: Decimal.parse('200'),
        ),
      );
      expect(r.pricePerLiter, Decimal.parse('5.0000'));
    });

    test('2 presentes (total+price), sem liters → liters = total / price', () {
      final r = computeMissingTriplet(
        FuelTriplet(
          pricePerLiter: Decimal.parse('5'),
          totalCost: Decimal.parse('200'),
        ),
      );
      expect(r.liters, Decimal.parse('40.0000'));
    });

    test('3 presentes → retorna unchanged', () {
      final input = FuelTriplet(
        liters: Decimal.parse('40'),
        pricePerLiter: Decimal.parse('5'),
        totalCost: Decimal.parse('999'), // valor "errado" não é recalculado
      );
      final r = computeMissingTriplet(input);
      expect(r.totalCost, Decimal.parse('999'));
    });

    test('0 presentes → retorna unchanged (todos null)', () {
      final r = computeMissingTriplet(const FuelTriplet());
      expect(r.liters, isNull);
      expect(r.pricePerLiter, isNull);
      expect(r.totalCost, isNull);
    });

    test('1 presente → retorna unchanged (não dá pra calcular)', () {
      final r = computeMissingTriplet(FuelTriplet(liters: Decimal.parse('40')));
      expect(r.liters, Decimal.parse('40'));
      expect(r.pricePerLiter, isNull);
      expect(r.totalCost, isNull);
    });

    test('precisão decimal exata: 43.219 × 5.799 = 250.626981', () {
      final r = computeMissingTriplet(
        FuelTriplet(
          liters: Decimal.parse('43.219'),
          pricePerLiter: Decimal.parse('5.799'),
        ),
      );
      expect(r.totalCost, Decimal.parse('250.626981'));
    });

    test('defensivo: liters=0 + total=200 → não divide por zero', () {
      final r = computeMissingTriplet(
        FuelTriplet(liters: Decimal.zero, totalCost: Decimal.parse('200')),
      );
      expect(r.pricePerLiter, isNull); // não calculou
    });

    test('defensivo: price=0 + total=200 → não divide por zero', () {
      final r = computeMissingTriplet(
        FuelTriplet(
          pricePerLiter: Decimal.zero,
          totalCost: Decimal.parse('200'),
        ),
      );
      expect(r.liters, isNull);
    });
  });
}
