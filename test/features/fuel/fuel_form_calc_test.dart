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

    test(
      'currency BRL: liters × price é arredondado a 2 casas (250.33, não 250.325)',
      () {
        final r = computeMissingTriplet(
          FuelTriplet(
            liters: Decimal.parse('42.5'),
            pricePerLiter: Decimal.parse('5.89'),
          ),
        );
        expect(r.totalCost, Decimal.parse('250.33'));
      },
    );

    test('currency BRL: 13.987 × 7.15 = 100.01 (regressão do scan 18/06)', () {
      final r = computeMissingTriplet(
        FuelTriplet(
          liters: Decimal.parse('13.987'),
          pricePerLiter: Decimal.parse('7.15'),
        ),
      );
      expect(r.totalCost, Decimal.parse('100.01'));
    });

    test('currency BRL: 30 × 5.89 = 176.70 (regressão do Total stale 18/06)', () {
      final r = computeMissingTriplet(
        FuelTriplet(
          liters: Decimal.parse('30'),
          pricePerLiter: Decimal.parse('5.89'),
        ),
      );
      expect(r.totalCost, Decimal.parse('176.70'));
    });

    group('exclude: recomputa o campo auto quando os 3 estão preenchidos', () {
      test(
        'exclude=totalCost + 3 preenchidos → ignora total atual, recomputa',
        () {
          final r = computeMissingTriplet(
            FuelTriplet(
              liters: Decimal.parse('30'),
              pricePerLiter: Decimal.parse('5.89'),
              totalCost: Decimal.parse('250.33'),
            ),
            exclude: FuelField.totalCost,
          );
          expect(r.totalCost, Decimal.parse('176.70'));
          expect(r.liters, Decimal.parse('30'));
          expect(r.pricePerLiter, Decimal.parse('5.89'));
        },
      );

      test('exclude=liters + 3 preenchidos → ignora liters atual, recomputa', () {
        final r = computeMissingTriplet(
          FuelTriplet(
            liters: Decimal.parse('99'),
            pricePerLiter: Decimal.parse('5'),
            totalCost: Decimal.parse('200'),
          ),
          exclude: FuelField.liters,
        );
        expect(r.liters, Decimal.parse('40.0000'));
      });

      test('exclude=pricePerLiter + 3 preenchidos → ignora price atual, recomputa', () {
        final r = computeMissingTriplet(
          FuelTriplet(
            liters: Decimal.parse('40'),
            pricePerLiter: Decimal.parse('9.99'),
            totalCost: Decimal.parse('200'),
          ),
          exclude: FuelField.pricePerLiter,
        );
        expect(r.pricePerLiter, Decimal.parse('5.0000'));
      });

      test('exclude=null + 3 preenchidos → unchanged (override manual antigo)', () {
        final r = computeMissingTriplet(
          FuelTriplet(
            liters: Decimal.parse('40'),
            pricePerLiter: Decimal.parse('5'),
            totalCost: Decimal.parse('999'),
          ),
        );
        expect(r.totalCost, Decimal.parse('999'));
      });
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
