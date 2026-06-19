// Validadores e helpers puros do formulário de abastecimento — Sprint 2.3.
// Funções puras, sem estado, testáveis isoladamente.
// Mensagens em PT-BR conforme spec.

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

/// Identifica qual dos três campos do triplet de abastecimento está sendo referido.
enum FuelField { liters, pricePerLiter, totalCost }

/// Triplet imutável com os três grandezas do abastecimento.
/// Qualquer campo pode ser null (não preenchido ou não calculável).
class FuelTriplet {
  const FuelTriplet({this.liters, this.pricePerLiter, this.totalCost});

  final Decimal? liters;
  final Decimal? pricePerLiter;
  final Decimal? totalCost;
}

/// Retorna a lista de [FuelType] permitidos para abastecer um veículo
/// do [vehicleType] informado.
///
/// Veículo flex aceita gasolina ou etanol (no abastecimento real escolhe um
/// dos dois — "flex" não é um combustível dispensável na bomba).
/// Todos os outros tipos aceitam apenas o próprio tipo.
List<FuelType> availableFuelTypesFor(FuelType vehicleType) {
  switch (vehicleType) {
    case FuelType.flex:
      return const [FuelType.gasolina, FuelType.etanol];
    case FuelType.gasolina:
      return const [FuelType.gasolina];
    case FuelType.etanol:
      return const [FuelType.etanol];
    case FuelType.diesel:
      return const [FuelType.diesel];
    case FuelType.gnv:
      return const [FuelType.gnv];
  }
}

/// Calcula o campo faltante quando exatamente 2 dos 3 estão presentes.
///
/// - n < 2: retorna [input] inalterado.
/// - n == 3 e [exclude] null: retorna [input] inalterado (override manual).
/// - n == 3 e [exclude] setado: anula o campo [exclude] e recomputa
///   (caso "campo auto stale" do form de abastecimento).
/// - n == 2: calcula o campo ausente e retorna novo [FuelTriplet].
///
/// Divisão usa `.toDecimal(scaleOnInfinitePrecision: 4).round(scale: 4)`.
/// Multiplicação (total = liters × price) é arredondada a 2 casas — currency
/// BRL é sempre 2 casas; sem isso o Total exibido e gravado vaza precisão
/// (ex.: 13,987 × 7,15 = 100,00705 em vez de 100,01).
/// Denominador zero → retorna inalterado (defensivo).
FuelTriplet computeMissingTriplet(FuelTriplet input, {FuelField? exclude}) {
  final liters = exclude == FuelField.liters ? null : input.liters;
  final price = exclude == FuelField.pricePerLiter ? null : input.pricePerLiter;
  final total = exclude == FuelField.totalCost ? null : input.totalCost;

  final n = [liters, price, total].where((v) => v != null).length;

  if (n != 2) return input; // <2 (não computável) ou 3 sem exclude (override)

  // Exatamente 2 presentes — calcula o faltante.
  if (liters == null) {
    // liters faltando → liters = total / price
    if (price == Decimal.zero) return input; // divisão por zero defensiva
    final result = (total! / price!)
        .toDecimal(scaleOnInfinitePrecision: 4)
        .round(scale: 4);
    return FuelTriplet(liters: result, pricePerLiter: price, totalCost: total);
  } else if (price == null) {
    // price faltando → price = total / liters
    if (liters == Decimal.zero) return input; // divisão por zero defensiva
    final result = (total! / liters)
        .toDecimal(scaleOnInfinitePrecision: 4)
        .round(scale: 4);
    return FuelTriplet(liters: liters, pricePerLiter: result, totalCost: total);
  } else {
    // total faltando → total = liters × price, arredondado a 2 casas (BRL).
    return FuelTriplet(
      liters: liters,
      pricePerLiter: price,
      totalCost: (liters * price).round(scale: 2),
    );
  }
}

/// Normaliza separador decimal pt-BR (vírgula → ponto) e parseia como [Decimal].
///
/// Faz trim antes de processar. Lança [FormatException] se o valor não for
/// parseável ou estiver vazio.
///
/// Nunca passa por [double] — usa [Decimal.parse] diretamente.
Decimal parseDecimalPtBr(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Valor vazio');
  }
  final normalized = trimmed.replaceAll(',', '.');
  try {
    return Decimal.parse(normalized);
  } catch (_) {
    throw FormatException('Não é um número decimal válido: $input');
  }
}

/// Valida um campo decimal positivo (litros, preço, etc.).
///
/// - vazio/null → "Informe $fieldLabel"
/// - não parseável → "Use apenas números (ex.: 43,219)"
/// - ≤ 0 → "Deve ser maior que zero"
/// - ok → null
String? validateDecimalPositive(String? raw, {required String fieldLabel}) {
  if (raw == null || raw.trim().isEmpty) {
    return 'Informe $fieldLabel';
  }
  final Decimal value;
  try {
    value = parseDecimalPtBr(raw);
  } on FormatException {
    return 'Use apenas números (ex.: 43,219)';
  }
  if (value <= Decimal.zero) {
    return 'Deve ser maior que zero';
  }
  return null;
}

/// Valida o odômetro no momento do abastecimento (inteiro, não negativo).
///
/// - vazio/null → "Informe o odômetro"
/// - não inteiro → "Use apenas números"
/// - negativo → "Não pode ser negativo"
/// - ok → null
String? validateOdometerAtFueling(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return 'Informe o odômetro';
  }
  final parsed = int.tryParse(raw.trim());
  if (parsed == null) {
    return 'Use apenas números';
  }
  if (parsed < 0) {
    return 'Não pode ser negativo';
  }
  return null;
}

/// Calcula o custo total do abastecimento.
///
/// Pura, dois [Decimal], nunca [double]. Resultado exato.
Decimal computeTotalCost(Decimal liters, Decimal pricePerLiter) =>
    liters * pricePerLiter;

/// Valida que (date, odometer) cabe na linha do tempo do veículo + respeita
/// o odômetro inicial. Retorna null se válido, ou mensagem PT-BR.
///
/// Regras (Sprint 3.8):
/// 1. [odometer] >= [initialOdometer] (sempre bloqueante).
/// 2. Cross-date monotônico estrito:
///    - Não pode haver entry com date < [date] e odometer > [odometer].
///    - Não pode haver entry com date > [date] e odometer < [odometer].
/// 3. Mesma data: sem restrição (não registramos hora do dia).
/// [excludeId] ignora a própria entry em modo edição.
String? validateOdometerForEntry({
  required DateTime date,
  required int odometer,
  required int initialOdometer,
  required List<FuelEntry> existing,
  String? excludeId,
}) {
  if (odometer < initialOdometer) {
    return 'Odômetro menor que o inicial do veículo ($initialOdometer km).';
  }
  final others = excludeId == null
      ? existing
      : existing.where((e) => e.id != excludeId).toList();

  // Pior anterior: maior odômetro entre entries com date < new_date (estrito).
  FuelEntry? worstPrior;
  for (final e in others.where((e) => e.date.isBefore(date))) {
    if (worstPrior == null || e.odometer > worstPrior.odometer) {
      worstPrior = e;
    }
  }
  if (worstPrior != null && worstPrior.odometer > odometer) {
    final dd = _fmtDate(worstPrior.date);
    return 'Já existe abastecimento em $dd com odômetro maior '
        '(${worstPrior.odometer} km) — anterior.';
  }

  // Pior posterior: menor odômetro entre entries com date > new_date.
  FuelEntry? worstNext;
  for (final e in others.where((e) => e.date.isAfter(date))) {
    if (worstNext == null || e.odometer < worstNext.odometer) {
      worstNext = e;
    }
  }
  if (worstNext != null && worstNext.odometer < odometer) {
    final dd = _fmtDate(worstNext.date);
    return 'Já existe abastecimento em $dd com odômetro menor '
        '(${worstNext.odometer} km) — posterior.';
  }

  return null;
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
