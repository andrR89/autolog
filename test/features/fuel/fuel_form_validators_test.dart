import 'package:autolog/features/fuel/fuel_form_validators.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 2.3 — parser/validadores/helper do form de abastecimento.
/// Spec: docs/specs/sprint-2.3-fuel-entry-form.md
void main() {
  group('parseDecimalPtBr', () {
    test('aceita vírgula como separador decimal', () {
      expect(parseDecimalPtBr('5,5'), Decimal.parse('5.5'));
      expect(parseDecimalPtBr('43,219'), Decimal.parse('43.219'));
    });

    test('aceita ponto também', () {
      expect(parseDecimalPtBr('5.5'), Decimal.parse('5.5'));
    });

    test('faz trim antes de parsear', () {
      expect(parseDecimalPtBr('  43,219  '), Decimal.parse('43.219'));
    });

    test('lança FormatException em inválidos', () {
      expect(() => parseDecimalPtBr('abc'), throwsFormatException);
      expect(() => parseDecimalPtBr(''), throwsFormatException);
    });

    test('alta precisão — roundtrip exato sem double', () {
      final big = Decimal.parse('12345678901234.123456789');
      expect(parseDecimalPtBr('12345678901234,123456789'), big);
    });
  });

  group('validateDecimalPositive', () {
    test('vazio/null retorna erro com fieldLabel', () {
      expect(
        validateDecimalPositive('', fieldLabel: 'litros'),
        'Informe litros',
      );
      expect(
        validateDecimalPositive(null, fieldLabel: 'preço'),
        'Informe preço',
      );
    });

    test('zero ou negativo retorna "Deve ser maior que zero"', () {
      expect(
        validateDecimalPositive('0', fieldLabel: 'litros'),
        'Deve ser maior que zero',
      );
      expect(
        validateDecimalPositive('-1', fieldLabel: 'litros'),
        'Deve ser maior que zero',
      );
      expect(
        validateDecimalPositive('-0,5', fieldLabel: 'litros'),
        'Deve ser maior que zero',
      );
    });

    test('não parseável retorna "Use apenas números..."', () {
      expect(
        validateDecimalPositive('abc', fieldLabel: 'litros'),
        'Use apenas números (ex.: 43,219)',
      );
    });

    test('valor positivo retorna null', () {
      expect(validateDecimalPositive('0,1', fieldLabel: 'litros'), isNull);
      expect(validateDecimalPositive('43,219', fieldLabel: 'litros'), isNull);
    });
  });

  group('validateOdometerAtFueling', () {
    test('vazio/null retorna erro', () {
      expect(validateOdometerAtFueling(''), isNotNull);
      expect(validateOdometerAtFueling(null), isNotNull);
    });

    test('não inteiro retorna erro', () {
      expect(validateOdometerAtFueling('abc'), isNotNull);
      expect(validateOdometerAtFueling('12,5'), isNotNull);
    });

    test('negativo retorna erro', () {
      expect(validateOdometerAtFueling('-1'), isNotNull);
    });

    test('zero e positivos válidos', () {
      expect(validateOdometerAtFueling('0'), isNull);
      expect(validateOdometerAtFueling('45000'), isNull);
    });
  });

  group('computeTotalCost', () {
    test('multiplica Decimal sem perder precisão', () {
      final liters = Decimal.parse('43.219');
      final price = Decimal.parse('5.799');
      // 43.219 × 5.799 = 250.626981 (43219 × 5799 = 250_626_981)
      expect(computeTotalCost(liters, price), Decimal.parse('250.626981'));
    });

    test('caso simples', () {
      expect(
        computeTotalCost(Decimal.parse('40'), Decimal.parse('5')),
        Decimal.parse('200'),
      );
    });
  });
}
