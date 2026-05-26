// Validadores puros do formulário de veículo — Sprint 1.3 + 6.E + 6.H.
// Funções puras, sem estado, testáveis isoladamente.
// Mensagens em PT-BR conforme spec.

import 'package:autolog/domain/models/enums.dart';
import 'package:decimal/decimal.dart';

/// Valida o apelido do veículo.
/// Retorna uma mensagem de erro PT-BR ou null se válido.
String? validateNickname(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe um apelido';
  }
  return null;
}

/// Valida o odômetro inicial (string vinda do campo de texto).
/// Retorna uma mensagem de erro PT-BR ou null se válido.
String? validateInitialOdometer(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Informe o odômetro inicial';
  }
  final parsed = int.tryParse(value.trim());
  if (parsed == null) {
    return 'Use apenas números';
  }
  if (parsed < 0) {
    return 'Não pode ser negativo';
  }
  return null;
}

/// Converte a string do campo de texto para int.
/// Lança [FormatException] se o valor não for um inteiro válido.
/// A UI deve validar com [validateInitialOdometer] antes de chamar isso.
int parseOdometer(String value) {
  final parsed = int.tryParse(value.trim());
  if (parsed == null) {
    throw FormatException('Odômetro inválido: $value');
  }
  return parsed;
}

// ---------------------------------------------------------------------------
// Sprint 6.E — campos opcionais: ano, UF, cor
// ---------------------------------------------------------------------------

/// Set canônico das 27 UFs brasileiras.
const Set<String> brUfs = {
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
  'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
  'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
};

/// Valida o ano do veículo. Campo opcional — vazio/null é válido (retorna null).
/// - Não-inteiro → "Use apenas números"
/// - < 1900 ou > currentYear+1 → "Ano inválido"
String? validateYear(String? raw, {DateTime? now}) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final parsed = int.tryParse(trimmed);
  if (parsed == null) return 'Use apenas números';

  final currentYear = (now ?? DateTime.now()).year;
  if (parsed < 1900 || parsed > currentYear + 1) return 'Ano inválido';

  return null;
}

/// Valida UF brasileira. Campo opcional — vazio/null é válido (retorna null).
/// - Não-2 letras → "UF deve ter 2 letras"
/// - 2 letras mas não consta nas 27 UFs → "UF inválida"
/// Trata lowercase via normalização interna.
String? validateUf(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  // Deve ter exatamente 2 caracteres alfabéticos.
  if (trimmed.length != 2 || !RegExp(r'^[a-zA-Z]{2}$').hasMatch(trimmed)) {
    return 'UF deve ter 2 letras';
  }

  final normalized = trimmed.toUpperCase();
  if (!brUfs.contains(normalized)) return 'UF inválida';

  return null;
}

/// Normaliza UF: trim + uppercase. Retorna null se vazio.
String? normalizeUf(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed.toUpperCase();
}

/// Parse opcional de ano: null se vazio/null, int se válido.
/// Lança [FormatException] se não for inteiro válido.
/// A UI deve validar com [validateYear] antes de chamar isso.
int? parseYearOptional(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final parsed = int.tryParse(trimmed);
  if (parsed == null) {
    throw FormatException('Ano inválido: $value');
  }
  return parsed;
}

// ---------------------------------------------------------------------------
// Sprint 6.H — specs técnicos: cilindrada, tanque, potência
// ---------------------------------------------------------------------------

/// Helper interno: parse Decimal aceitando vírgula PT-BR.
/// Lança [FormatException] se inválido.
Decimal _parseDecimalPtBr(String input) {
  final normalized = input.trim().replaceAll(',', '.');
  if (normalized.isEmpty) throw const FormatException('Valor vazio');
  try {
    return Decimal.parse(normalized);
  } catch (_) {
    throw FormatException('Não é um número decimal válido: $input');
  }
}

/// Valida cilindrada em cc. Campo opcional — vazio/null retorna null.
/// - Não-inteiro (inclui decimais) → "Use apenas números"
/// - < 50 ou > 9999 → "Cilindrada inválida"
String? validateEngineCc(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final parsed = int.tryParse(trimmed);
  if (parsed == null) return 'Use apenas números';

  if (parsed < 50 || parsed > 9999) return 'Cilindrada inválida';

  return null;
}

/// Valida capacidade do tanque em litros. Campo opcional — vazio/null retorna null.
/// Aceita vírgula PT-BR (ex.: "12,5"). Usa Decimal para precisão.
/// - Não-decimal → "Use apenas números"
/// - < 0.5 ou > 500 → "Capacidade inválida"
String? validateTankL(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final Decimal parsed;
  try {
    parsed = _parseDecimalPtBr(trimmed);
  } on FormatException {
    return 'Use apenas números';
  }

  final min = Decimal.parse('0.5');
  final max = Decimal.parse('500');
  if (parsed < min || parsed > max) return 'Capacidade inválida';

  return null;
}

/// Valida potência em cv. Campo opcional — vazio/null retorna null.
/// - Não-inteiro (inclui decimais e negativos não-inteiros) → "Use apenas números"
/// - <= 0 ou > 2000 → "Potência inválida"
String? validateHorsepower(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final parsed = int.tryParse(trimmed);
  if (parsed == null) return 'Use apenas números';

  if (parsed <= 0 || parsed > 2000) return 'Potência inválida';

  return null;
}

/// Formata cilindrada para exibição:
/// - carro: "1.6 L (1600 cc)" (L com 1 casa decimal)
/// - moto: "250 cc"
String formatEngineDisplay(int cc, VehicleType type) {
  if (type == VehicleType.moto) {
    return '$cc cc';
  }
  final liters = (cc / 1000).toStringAsFixed(1);
  return '$liters L ($cc cc)';
}

/// Parse opcional de cilindrada: null se vazio/null, int se válido.
/// Lança [FormatException] se não for inteiro válido.
int? parseEngineCcOptional(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final parsed = int.tryParse(trimmed);
  if (parsed == null) throw FormatException('Cilindrada inválida: $raw');
  return parsed;
}

/// Parse opcional do tanque em litros: null se vazio/null, Decimal se válido.
/// Aceita vírgula PT-BR. Lança [FormatException] se inválido.
Decimal? parseTankLOptional(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return _parseDecimalPtBr(trimmed);
}

/// Parse opcional de potência: null se vazio/null, int se válido.
/// Lança [FormatException] se não for inteiro válido.
int? parseHorsepowerOptional(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final parsed = int.tryParse(trimmed);
  if (parsed == null) throw FormatException('Potência inválida: $raw');
  return parsed;
}

// ---------------------------------------------------------------------------
// Sprint 6.K — RENAVAM e Chassi
// ---------------------------------------------------------------------------

/// Valida o RENAVAM do veículo. Campo opcional — vazio/null retorna null.
/// - Não-numérico → "Use apenas números"
/// - Comprimento fora de [9, 11] → "RENAVAM deve ter 9 a 11 dígitos"
String? validateRenavam(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
    return 'Use apenas números';
  }

  if (trimmed.length < 9 || trimmed.length > 11) {
    return 'RENAVAM deve ter 9 a 11 dígitos';
  }

  return null;
}

/// Valida o chassi (VIN) do veículo. Campo opcional — vazio/null retorna null.
/// Aceita minúsculo (normaliza para maiúsculo internamente).
/// - Comprimento != 17 → "Chassi deve ter 17 caracteres"
/// - Caracteres não-alfanuméricos (espaço, hífen, etc.) → "Use apenas letras e números"
String? validateChassi(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final upper = trimmed.toUpperCase();

  if (upper.length != 17) {
    return 'Chassi deve ter 17 caracteres';
  }

  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(upper)) {
    return 'Use apenas letras e números';
  }

  return null;
}
