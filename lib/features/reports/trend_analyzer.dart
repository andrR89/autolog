import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

// ============================================================================
// Tipos públicos
// ============================================================================

enum TrendDirection { up, down, stable }

/// Resultado de uma análise de tendência comparando duas janelas de tempo.
class TrendAnalysis {
  const TrendAnalysis({
    required this.direction,
    required this.deltaPercent,
    required this.currentValue,
    required this.previousValue,
    required this.hasEnoughData,
  });

  final TrendDirection direction;

  /// Delta percentual: positivo = subiu, negativo = caiu.
  final Decimal deltaPercent;

  /// Valor médio na janela atual.
  final Decimal currentValue;

  /// Valor médio na janela anterior.
  final Decimal previousValue;

  /// false quando alguma janela não tem dados suficientes (< 2 fuel entries
  /// pra consumo, ou previous = 0 pra spending).
  final bool hasEnoughData;
}

// ============================================================================
// API pública
// ============================================================================

/// Analisa a tendência de consumo (km/L) comparando a janela atual com a
/// janela imediatamente anterior de mesmo tamanho.
///
/// [entries] devem ser do mesmo veículo (qualquer ordem).
/// [windowSize] padrão: 90 dias.
/// [stableThreshold]: variação ≤ X% → [TrendDirection.stable] (padrão 5%).
TrendAnalysis analyzeConsumptionTrend({
  required List<FuelEntry> entries,
  required DateTime now,
  Duration windowSize = const Duration(days: 90),
  Decimal? stableThreshold,
}) {
  final threshold = stableThreshold ?? Decimal.parse('5');

  final currentWindow = _filterWindow(
    entries,
    from: now.subtract(windowSize),
    to: now,
  );
  final previousWindow = _filterWindow(
    entries,
    from: now.subtract(windowSize * 2),
    to: now.subtract(windowSize),
  );

  final currentKmL = _computeAverageKmL(currentWindow);
  final previousKmL = _computeAverageKmL(previousWindow);

  if (currentKmL == null || previousKmL == null) {
    return _noData();
  }

  if (previousKmL == Decimal.zero) {
    return _noData();
  }

  return _buildAnalysis(
    current: currentKmL,
    previous: previousKmL,
    threshold: threshold,
  );
}

/// Analisa a tendência de gasto (combustível + despesas) comparando as duas
/// janelas de tempo de mesmo tamanho.
TrendAnalysis analyzeSpendingTrend({
  required List<FuelEntry> fuels,
  required List<Expense> expenses,
  required DateTime now,
  Duration windowSize = const Duration(days: 90),
  Decimal? stableThreshold,
}) {
  final threshold = stableThreshold ?? Decimal.parse('5');

  final currentFuels = _filterWindow(
    fuels,
    from: now.subtract(windowSize),
    to: now,
  );
  final previousFuels = _filterWindow(
    fuels,
    from: now.subtract(windowSize * 2),
    to: now.subtract(windowSize),
  );
  final currentExpenses = _filterExpenseWindow(
    expenses,
    from: now.subtract(windowSize),
    to: now,
  );
  final previousExpenses = _filterExpenseWindow(
    expenses,
    from: now.subtract(windowSize * 2),
    to: now.subtract(windowSize),
  );

  final currentSpend = _totalSpending(currentFuels, currentExpenses);
  final previousSpend = _totalSpending(previousFuels, previousExpenses);

  // Sem dados em ambas as janelas → não há o que comparar.
  if (currentSpend == Decimal.zero && previousSpend == Decimal.zero) {
    return _noData();
  }

  if (previousSpend == Decimal.zero) {
    return _noData();
  }

  return _buildAnalysis(
    current: currentSpend,
    previous: previousSpend,
    threshold: threshold,
  );
}

// ============================================================================
// Helpers internos
// ============================================================================

/// Filtra entries cuja [date] está em [from, to) (from inclusivo, to exclusivo).
List<FuelEntry> _filterWindow(
  List<FuelEntry> entries, {
  required DateTime from,
  required DateTime to,
}) {
  return entries
      .where((e) => !e.date.isBefore(from) && e.date.isBefore(to))
      .toList();
}

List<Expense> _filterExpenseWindow(
  List<Expense> expenses, {
  required DateTime from,
  required DateTime to,
}) {
  return expenses
      .where((e) => !e.date.isBefore(from) && e.date.isBefore(to))
      .toList();
}

/// Média km/L da janela usando odômetros.
///
/// Retorna null se a janela tiver < 2 entries (sem baseline).
Decimal? _computeAverageKmL(List<FuelEntry> entries) {
  if (entries.length < 2) return null;

  var minOdo = entries.first.odometer;
  var maxOdo = entries.first.odometer;
  var totalLiters = Decimal.zero;

  for (final e in entries) {
    if (e.odometer < minOdo) minOdo = e.odometer;
    if (e.odometer > maxOdo) maxOdo = e.odometer;
    totalLiters = totalLiters + e.liters;
  }

  final km = maxOdo - minOdo;
  if (km <= 0 || totalLiters == Decimal.zero) return null;

  return (Decimal.fromInt(km) / totalLiters)
      .toDecimal(scaleOnInfinitePrecision: 5)
      .round(scale: 4);
}

/// Soma do custo total (combustível + despesas) na janela.
Decimal _totalSpending(List<FuelEntry> fuels, List<Expense> expenses) {
  var total = Decimal.zero;
  for (final f in fuels) {
    total = total + f.totalCost;
  }
  for (final x in expenses) {
    total = total + x.amount;
  }
  return total;
}

/// Constrói [TrendAnalysis] com dados suficientes.
TrendAnalysis _buildAnalysis({
  required Decimal current,
  required Decimal previous,
  required Decimal threshold,
}) {
  // deltaPercent = ((current - previous) / previous) * 100
  // Note: Decimal / Decimal returns Rational — must call toDecimal() first.
  final deltaRatio = ((current - previous) / previous)
      .toDecimal(scaleOnInfinitePrecision: 5);
  final deltaPercent =
      (deltaRatio * Decimal.fromInt(100)).round(scale: 4);

  final TrendDirection direction;
  if (deltaPercent > threshold) {
    direction = TrendDirection.up;
  } else if (deltaPercent < -threshold) {
    direction = TrendDirection.down;
  } else {
    direction = TrendDirection.stable;
  }

  return TrendAnalysis(
    direction: direction,
    deltaPercent: deltaPercent,
    currentValue: current,
    previousValue: previous,
    hasEnoughData: true,
  );
}

/// Retorna uma análise com [hasEnoughData]=false e valores neutros.
TrendAnalysis _noData() {
  return TrendAnalysis(
    direction: TrendDirection.stable,
    deltaPercent: Decimal.zero,
    currentValue: Decimal.zero,
    previousValue: Decimal.zero,
    hasEnoughData: false,
  );
}
