import 'package:autolog/features/personal_documents/document_validators.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 6.O — Validadores de documentos pessoais.
void main() {
  group('validateCnhNumber', () {
    test('null → null (opcional)', () {
      expect(validateCnhNumber(null), isNull);
    });

    test('vazio → null (opcional)', () {
      expect(validateCnhNumber(''), isNull);
      expect(validateCnhNumber('   '), isNull);
    });

    test('não dígitos → mensagem de erro', () {
      expect(validateCnhNumber('ABC12345'), 'Use apenas números');
      expect(validateCnhNumber('123-456'), 'Use apenas números');
    });

    test('menos de 9 dígitos → mensagem de comprimento', () {
      expect(validateCnhNumber('12345678'), 'CNH deve ter 9 a 11 dígitos');
    });

    test('mais de 11 dígitos → mensagem de comprimento', () {
      expect(validateCnhNumber('123456789012'), 'CNH deve ter 9 a 11 dígitos');
    });

    test('9 dígitos → ok', () {
      expect(validateCnhNumber('123456789'), isNull);
    });

    test('10 dígitos → ok', () {
      expect(validateCnhNumber('1234567890'), isNull);
    });

    test('11 dígitos → ok', () {
      expect(validateCnhNumber('01234567891'), isNull);
    });
  });

  group('validatePoints', () {
    test('null → null (opcional)', () {
      expect(validatePoints(null), isNull);
    });

    test('vazio → null (opcional)', () {
      expect(validatePoints(''), isNull);
    });

    test('não inteiro → mensagem de erro', () {
      expect(validatePoints('abc'), 'Use apenas números');
      expect(validatePoints('3.5'), 'Use apenas números');
    });

    test('negativo → mensagem de faixa', () {
      expect(validatePoints('-1'), 'Pontos devem ser entre 0 e 40');
    });

    test('acima de 40 → mensagem de faixa', () {
      expect(validatePoints('41'), 'Pontos devem ser entre 0 e 40');
    });

    test('0 → ok', () {
      expect(validatePoints('0'), isNull);
    });

    test('40 → ok', () {
      expect(validatePoints('40'), isNull);
    });

    test('7 → ok', () {
      expect(validatePoints('7'), isNull);
    });
  });

  group('validateAmount', () {
    test('null → mensagem de obrigatório', () {
      expect(validateAmount(null), 'Informe o valor');
    });

    test('vazio → mensagem de obrigatório', () {
      expect(validateAmount(''), 'Informe o valor');
    });

    test('não numérico → mensagem de formato', () {
      expect(validateAmount('abc'), 'Use apenas números (ex.: 189,90)');
    });

    test('zero → mensagem de positivo', () {
      expect(validateAmount('0'), 'Deve ser maior que zero');
    });

    test('negativo → mensagem de positivo', () {
      expect(validateAmount('-10'), 'Deve ser maior que zero');
    });

    test('válido com ponto → ok', () {
      expect(validateAmount('189.90'), isNull);
    });

    test('válido com vírgula pt-BR → ok', () {
      expect(validateAmount('293,47'), isNull);
    });
  });

  group('validateAmountOptional', () {
    test('null → null', () {
      expect(validateAmountOptional(null), isNull);
    });

    test('vazio → null', () {
      expect(validateAmountOptional(''), isNull);
    });

    test('valor válido → null', () {
      expect(validateAmountOptional('100,00'), isNull);
    });

    test('valor inválido → mensagem', () {
      expect(validateAmountOptional('abc'), 'Use apenas números (ex.: 189,90)');
    });
  });

  group('parseAmountOptional', () {
    test('null → null', () {
      expect(parseAmountOptional(null), isNull);
    });

    test('vazio → null', () {
      expect(parseAmountOptional(''), isNull);
    });

    test('valor com vírgula → Decimal correto', () {
      final result = parseAmountOptional('1.200,00');
      expect(result, Decimal.parse('1200'));
    });
  });
}
