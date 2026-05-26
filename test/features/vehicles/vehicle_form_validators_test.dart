import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/vehicles/vehicle_form_validators.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sprint 1.3 — validadores do formulário de veículo.
/// Spec: docs/specs/sprint-1.3-vehicles-ui.md
void main() {
  group('validateNickname', () {
    test('vazio ou null retorna erro PT-BR', () {
      expect(validateNickname(''), 'Informe um apelido');
      expect(validateNickname(null), 'Informe um apelido');
      expect(validateNickname('   '), 'Informe um apelido');
    });

    test('apelido válido retorna null', () {
      expect(validateNickname('Meu Civic'), isNull);
    });
  });

  group('validateInitialOdometer', () {
    test('vazio ou null retorna erro', () {
      expect(validateInitialOdometer(''), isNotNull);
      expect(validateInitialOdometer(null), isNotNull);
    });

    test('não-numérico retorna erro específico', () {
      expect(validateInitialOdometer('abc'), 'Use apenas números');
      expect(validateInitialOdometer('12.5'), 'Use apenas números');
    });

    test('negativo retorna erro específico', () {
      expect(validateInitialOdometer('-1'), 'Não pode ser negativo');
    });

    test('zero é válido (carro novo)', () {
      expect(validateInitialOdometer('0'), isNull);
    });

    test('positivo é válido', () {
      expect(validateInitialOdometer('45000'), isNull);
    });
  });

  group('parseOdometer', () {
    test('inteiro válido retorna int', () {
      expect(parseOdometer('45000'), 45000);
      expect(parseOdometer('0'), 0);
    });

    test('inválido lança FormatException', () {
      expect(() => parseOdometer('abc'), throwsFormatException);
      expect(() => parseOdometer('12.5'), throwsFormatException);
    });
  });

  // Sprint 6.E — campos opcionais expandidos.
  // Spec: docs/specs/sprint-6.E-vehicle-extended-fields.md

  group('validateYear', () {
    // Now fixo: 25/05/2026 → currentYear+1 = 2027 ainda válido; 2028 inválido.
    final now = DateTime(2026, 5, 25);

    test('vazio/null/whitespace → null (opcional)', () {
      expect(validateYear(null, now: now), isNull);
      expect(validateYear('', now: now), isNull);
      expect(validateYear('   ', now: now), isNull);
    });

    test('não-numérico → erro', () {
      expect(validateYear('abc', now: now), 'Use apenas números');
      expect(validateYear('20.5', now: now), 'Use apenas números');
    });

    test('< 1900 → "Ano inválido"', () {
      expect(validateYear('1899', now: now), 'Ano inválido');
      expect(validateYear('0', now: now), 'Ano inválido');
    });

    test('> currentYear+1 → "Ano inválido"', () {
      expect(validateYear('2028', now: now), 'Ano inválido');
      expect(validateYear('9999', now: now), 'Ano inválido');
    });

    test('range válido [1900, currentYear+1]', () {
      expect(validateYear('1900', now: now), isNull);
      expect(validateYear('2020', now: now), isNull);
      expect(validateYear('2026', now: now), isNull);
      expect(validateYear('2027', now: now), isNull);
    });
  });

  group('validateUf', () {
    test('vazio/null/whitespace → null (opcional)', () {
      expect(validateUf(null), isNull);
      expect(validateUf(''), isNull);
      expect(validateUf('   '), isNull);
    });

    test('!= 2 caracteres → "UF deve ter 2 letras"', () {
      expect(validateUf('S'), 'UF deve ter 2 letras');
      expect(validateUf('SPP'), 'UF deve ter 2 letras');
    });

    test('lowercase aceito (normalização interna)', () {
      expect(validateUf('sp'), isNull);
      expect(validateUf('rj'), isNull);
    });

    test('UF brasileira válida → null', () {
      expect(validateUf('SP'), isNull);
      expect(validateUf('RJ'), isNull);
      expect(validateUf('TO'), isNull);
      expect(validateUf('DF'), isNull);
    });

    test('código não-UF → "UF inválida"', () {
      expect(validateUf('XX'), 'UF inválida');
      expect(validateUf('ZZ'), 'UF inválida');
    });

    test('não-alfabético → "UF deve ter 2 letras"', () {
      expect(validateUf('12'), 'UF deve ter 2 letras');
      expect(validateUf('S1'), 'UF deve ter 2 letras');
    });
  });

  group('normalizeUf', () {
    test('vazio/null → null', () {
      expect(normalizeUf(null), isNull);
      expect(normalizeUf(''), isNull);
      expect(normalizeUf('   '), isNull);
    });

    test('trim + uppercase', () {
      expect(normalizeUf('sp'), 'SP');
      expect(normalizeUf(' rj '), 'RJ');
      expect(normalizeUf('TO'), 'TO');
    });
  });

  group('parseYearOptional', () {
    test('vazio/null → null', () {
      expect(parseYearOptional(null), isNull);
      expect(parseYearOptional(''), isNull);
      expect(parseYearOptional('   '), isNull);
    });

    test('inteiro válido', () {
      expect(parseYearOptional('2020'), 2020);
    });

    test('inválido lança FormatException', () {
      expect(() => parseYearOptional('abc'), throwsFormatException);
    });
  });

  group('brUfs', () {
    test('contém as 27 UFs brasileiras', () {
      expect(brUfs.length, 27);
      expect(brUfs, containsAll(<String>[
        'AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG',
        'PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO',
      ]));
    });
  });

  // Sprint 6.H — specs técnicos do veículo.
  // Spec: docs/specs/sprint-6.H-vehicle-type-and-specs.md

  group('validateEngineCc', () {
    test('vazio/null → null (opcional)', () {
      expect(validateEngineCc(null), isNull);
      expect(validateEngineCc(''), isNull);
      expect(validateEngineCc('   '), isNull);
    });

    test('não-numérico → erro', () {
      expect(validateEngineCc('abc'), 'Use apenas números');
      expect(validateEngineCc('1.6'), 'Use apenas números');
    });

    test('< 50 cc → erro', () {
      expect(validateEngineCc('0'), 'Cilindrada inválida');
      expect(validateEngineCc('49'), 'Cilindrada inválida');
    });

    test('> 9999 cc → erro', () {
      expect(validateEngineCc('10000'), 'Cilindrada inválida');
    });

    test('range válido [50, 9999]', () {
      expect(validateEngineCc('50'), isNull);
      expect(validateEngineCc('125'), isNull);
      expect(validateEngineCc('1600'), isNull);
      expect(validateEngineCc('9999'), isNull);
    });
  });

  group('validateTankL', () {
    test('vazio/null → null (opcional)', () {
      expect(validateTankL(null), isNull);
      expect(validateTankL(''), isNull);
    });

    test('não-numérico → erro', () {
      expect(validateTankL('abc'), 'Use apenas números');
    });

    test('< 0.5 L → erro', () {
      expect(validateTankL('0.4'), 'Capacidade inválida');
      expect(validateTankL('0'), 'Capacidade inválida');
    });

    test('> 500 L → erro', () {
      expect(validateTankL('501'), 'Capacidade inválida');
    });

    test('aceita vírgula PT-BR', () {
      expect(validateTankL('12,5'), isNull);
      expect(validateTankL('60,0'), isNull);
    });

    test('range válido [0.5, 500]', () {
      expect(validateTankL('0.5'), isNull);
      expect(validateTankL('17.3'), isNull);
      expect(validateTankL('47.0'), isNull);
      expect(validateTankL('500'), isNull);
    });
  });

  group('validateHorsepower', () {
    test('vazio/null → null (opcional)', () {
      expect(validateHorsepower(null), isNull);
      expect(validateHorsepower(''), isNull);
    });

    test('não-numérico → erro', () {
      expect(validateHorsepower('abc'), 'Use apenas números');
      expect(validateHorsepower('120.5'), 'Use apenas números');
    });

    test('<= 0 → erro', () {
      expect(validateHorsepower('0'), 'Potência inválida');
      expect(validateHorsepower('-10'), 'Potência inválida');
    });

    test('> 2000 → erro', () {
      expect(validateHorsepower('2001'), 'Potência inválida');
    });

    test('range válido [1, 2000]', () {
      expect(validateHorsepower('1'), isNull);
      expect(validateHorsepower('124'), isNull);
      expect(validateHorsepower('780'), isNull);
      expect(validateHorsepower('2000'), isNull);
    });
  });

  group('formatEngineDisplay', () {
    test('carro mostra L com 1 casa + cc entre parênteses', () {
      expect(formatEngineDisplay(1600, VehicleType.carro), '1.6 L (1600 cc)');
      expect(formatEngineDisplay(2000, VehicleType.carro), '2.0 L (2000 cc)');
      expect(formatEngineDisplay(1000, VehicleType.carro), '1.0 L (1000 cc)');
      expect(formatEngineDisplay(998, VehicleType.carro), '1.0 L (998 cc)');
    });

    test('moto mostra só cc', () {
      expect(formatEngineDisplay(250, VehicleType.moto), '250 cc');
      expect(formatEngineDisplay(600, VehicleType.moto), '600 cc');
      expect(formatEngineDisplay(125, VehicleType.moto), '125 cc');
    });
  });

  group('parseEngineCcOptional / parseTankLOptional / parseHorsepowerOptional', () {
    test('vazio/null → null', () {
      expect(parseEngineCcOptional(null), isNull);
      expect(parseEngineCcOptional(''), isNull);
      expect(parseTankLOptional(null), isNull);
      expect(parseTankLOptional(''), isNull);
      expect(parseHorsepowerOptional(null), isNull);
      expect(parseHorsepowerOptional(''), isNull);
    });

    test('válidos retornam valor tipado', () {
      expect(parseEngineCcOptional('1600'), 1600);
      expect(parseTankLOptional('17,3'), Decimal.parse('17.3'));
      expect(parseHorsepowerOptional('124'), 124);
    });

    test('inválidos lançam FormatException', () {
      expect(() => parseEngineCcOptional('abc'), throwsFormatException);
      expect(() => parseTankLOptional('xyz'), throwsFormatException);
      expect(() => parseHorsepowerOptional('abc'), throwsFormatException);
    });
  });

  // Sprint 6.K — RENAVAM + chassi
  // Spec: docs/specs/sprint-6.K-scan-crlv.md

  group('validateRenavam', () {
    test('vazio/null → null (opcional)', () {
      expect(validateRenavam(null), isNull);
      expect(validateRenavam(''), isNull);
      expect(validateRenavam('   '), isNull);
    });

    test('não-numérico → erro', () {
      expect(validateRenavam('abc'), 'Use apenas números');
      expect(validateRenavam('1234abc'), 'Use apenas números');
    });

    test('curto demais (< 9) → erro', () {
      expect(validateRenavam('12345678'), 'RENAVAM deve ter 9 a 11 dígitos');
    });

    test('longo demais (> 11) → erro', () {
      expect(validateRenavam('123456789012'), 'RENAVAM deve ter 9 a 11 dígitos');
    });

    test('válido (9, 10 ou 11 dígitos)', () {
      expect(validateRenavam('123456789'), isNull);
      expect(validateRenavam('1234567890'), isNull);
      expect(validateRenavam('12345678901'), isNull);
    });
  });

  group('validateChassi', () {
    test('vazio/null → null (opcional)', () {
      expect(validateChassi(null), isNull);
      expect(validateChassi(''), isNull);
    });

    test('!= 17 caracteres → erro', () {
      expect(validateChassi('ABC'), 'Chassi deve ter 17 caracteres');
      expect(validateChassi('9BWZZZ377VT00425'), 'Chassi deve ter 17 caracteres'); // 16
      expect(validateChassi('9BWZZZ377VT0042511'), 'Chassi deve ter 17 caracteres'); // 18
    });

    test('com espaço ou hífen → erro', () {
      expect(validateChassi('9BWZZZ377VT 04251'),
          'Use apenas letras e números');
      expect(validateChassi('9BWZZZ377VT-04251'),
          'Use apenas letras e números');
    });

    test('17 alfanuméricos maiúsculos → null', () {
      expect(validateChassi('9BWZZZ377VT004251'), isNull);
      expect(validateChassi('1HGCM82633A123456'), isNull);
    });

    test('aceita minúsculo (normaliza)', () {
      expect(validateChassi('9bwzzz377vt004251'), isNull);
    });
  });
}
