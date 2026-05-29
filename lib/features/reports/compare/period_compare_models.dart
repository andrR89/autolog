import 'package:decimal/decimal.dart';

/// Resumo agregado de um período (mês ou ano).
class PeriodSummary {
  const PeriodSummary({
    required this.label,
    required this.from,
    required this.to,
    required this.totalSpent,
    required this.totalLiters,
    required this.totalKm,
    required this.entriesCount,
    this.avgConsumption,
    this.avgPricePerLiter,
  });

  /// Rótulo legível, ex: "Maio 2026" ou "2026".
  final String label;

  final DateTime from;
  final DateTime to;

  /// Total gasto (combustível + despesas) no período.
  final Decimal totalSpent;

  /// Total de litros abastecidos no período.
  final Decimal totalLiters;

  /// Distância estimada (max(odômetro) − min(odômetro)) no período.
  final int totalKm;

  /// Número de abastecimentos no período.
  final int entriesCount;

  /// Consumo médio em km/L. null quando baseline insuficiente (Regra #2).
  final Decimal? avgConsumption;

  /// Preço médio ponderado por litro. null quando sem abastecimentos.
  final Decimal? avgPricePerLiter;
}

/// Par de períodos (atual × anterior) com deltas computados.
class PeriodCompareData {
  const PeriodCompareData({required this.current, required this.previous});

  final PeriodSummary current;
  final PeriodSummary previous;

  // ---------------------------------------------------------------------------
  // Deltas computados — null quando não é possível calcular (divisão por zero,
  // baseline insuficiente ou período vazio).
  // ---------------------------------------------------------------------------

  /// Variação percentual do gasto total: positivo = gastou mais, negativo = gastou menos.
  /// null quando previous.totalSpent == 0.
  Decimal? get totalSpentDeltaPercent {
    if (previous.totalSpent == Decimal.zero) return null;
    // Decimal / Decimal retorna Rational; toDecimal() converte de volta.
    final ratio =
        ((current.totalSpent - previous.totalSpent) / previous.totalSpent)
            .toDecimal(scaleOnInfinitePrecision: 4);
    return (ratio * Decimal.fromInt(100)).round(scale: 4);
  }

  /// Variação percentual dos litros: positivo = abasteceu mais.
  /// null quando previous.totalLiters == 0.
  Decimal? get litersDeltaPercent {
    if (previous.totalLiters == Decimal.zero) return null;
    final ratio =
        ((current.totalLiters - previous.totalLiters) / previous.totalLiters)
            .toDecimal(scaleOnInfinitePrecision: 4);
    return (ratio * Decimal.fromInt(100)).round(scale: 4);
  }

  /// Diferença absoluta de consumo (km/L): positivo = melhorou, negativo = piorou.
  /// null quando qualquer lado não tem baseline suficiente.
  Decimal? get avgConsumptionDelta {
    final curr = current.avgConsumption;
    final prev = previous.avgConsumption;
    if (curr == null || prev == null) return null;
    return curr - prev;
  }

  /// Diferença absoluta de distância (km): positivo = rodou mais.
  /// Nunca null (zero quando ambos são zero).
  int get distanceDelta => current.totalKm - previous.totalKm;
}
