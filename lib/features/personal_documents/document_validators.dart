// Validadores de campos de documentos pessoais — Sprint 6.O.
// Funções puras, sem estado, testáveis isoladamente.
// Mensagens em PT-BR conforme spec.

import 'package:autolog/features/fuel/fuel_form_validators.dart';
import 'package:decimal/decimal.dart';

/// Valida o número da CNH.
///
/// - vazio/null → null (campo opcional)
/// - não dígitos → "Use apenas números"
/// - fora de 9-11 dígitos → "CNH deve ter 9 a 11 dígitos"
/// - ok → null
String? validateCnhNumber(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null; // opcional

  final trimmed = raw.trim();
  // Deve conter apenas dígitos.
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
    return 'Use apenas números';
  }
  if (trimmed.length < 9 || trimmed.length > 11) {
    return 'CNH deve ter 9 a 11 dígitos';
  }
  return null;
}

/// Valida pontos de CNH.
///
/// - vazio/null → null (campo opcional)
/// - não inteiro → "Use apenas números"
/// - fora de 0-40 → "Pontos devem ser entre 0 e 40"
/// - ok → null
String? validatePoints(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null; // opcional

  final trimmed = raw.trim();
  final parsed = int.tryParse(trimmed);
  if (parsed == null) {
    return 'Use apenas números';
  }
  if (parsed < 0 || parsed > 40) {
    return 'Pontos devem ser entre 0 e 40';
  }
  return null;
}

/// Valida valor monetário obrigatório (reusa parseDecimalPtBr).
///
/// - vazio/null → "Informe o valor"
/// - não parseável → "Use apenas números (ex.: 189,90)"
/// - ≤ 0 → "Deve ser maior que zero"
/// - ok → null
String? validateAmount(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return 'Informe o valor';
  }
  final Decimal value;
  try {
    value = parseDecimalPtBr(raw);
  } on FormatException {
    return 'Use apenas números (ex.: 189,90)';
  }
  if (value <= Decimal.zero) {
    return 'Deve ser maior que zero';
  }
  return null;
}

/// Valida valor monetário opcional — vazio é OK.
///
/// - vazio/null → null
/// - não parseável → "Use apenas números (ex.: 189,90)"
/// - ≤ 0 → "Deve ser maior que zero"
/// - ok → null
String? validateAmountOptional(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return validateAmount(raw);
}

/// Parseia valor monetário opcional — retorna null se vazio.
/// Lança [FormatException] se não-vazio e inválido.
///
/// Suporta:
/// - PT-BR com separador de milhar: `1.200,00` → 1200.00
/// - PT-BR sem milhar: `293,47` → 293.47
/// - US: `189.90` → 189.90
Decimal? parseAmountOptional(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final trimmed = raw.trim();
  // Se contém vírgula E ponto, trata como PT-BR com separador de milhar:
  // remove pontos (milhar) e substitui vírgula por ponto.
  if (trimmed.contains(',') && trimmed.contains('.')) {
    final normalized = trimmed.replaceAll('.', '').replaceAll(',', '.');
    try {
      return Decimal.parse(normalized);
    } catch (_) {
      throw FormatException('Não é um número decimal válido: $raw');
    }
  }
  return parseDecimalPtBr(trimmed);
}
