import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

/// Estatísticas agregadas de uma viagem — calculadas a partir de listas
/// de [FuelEntry] e [Expense] filtradas pelo intervalo [start, end].
class TripStats {
  const TripStats({
    required this.fuelCount,
    required this.expenseCount,
    required this.fuelSpent,
    required this.expensesSpent,
    required this.totalSpent,
    required this.kmDriven,
    required this.avgConsumptionKmL,
    required this.days,
  });

  /// Quantidade de abastecimentos no intervalo.
  final int fuelCount;

  /// Quantidade de despesas no intervalo.
  final int expenseCount;

  /// Total gasto em combustível no intervalo.
  final Decimal fuelSpent;

  /// Total gasto em despesas no intervalo.
  final Decimal expensesSpent;

  /// Total gasto (fuel + expenses).
  final Decimal totalSpent;

  /// Quilômetros rodados: max(odometer) - min(odometer) das fuel entries
  /// no intervalo. Zero se menos de 2 entries.
  final int kmDriven;

  /// Consumo médio (km/l). Null se kmDriven == 0.
  final Decimal? avgConsumptionKmL;

  /// Duração da viagem em dias (inclusivo: end - start + 1).
  final int days;
}

/// Calcula estatísticas de uma viagem filtrando [fuels] e [expenses]
/// pelo intervalo [start, end] (inclusive em ambos os lados).
TripStats computeTripStats({
  required DateTime start,
  required DateTime end,
  required List<FuelEntry> fuels,
  required List<Expense> expenses,
}) {
  // Normaliza para comparação de data (ignora hora).
  final startDay = DateTime.utc(start.year, start.month, start.day);
  final endDay = DateTime.utc(end.year, end.month, end.day);

  // Filtra por date in [start, end] (comparação por dia).
  final filteredFuels = fuels.where((f) {
    final d = DateTime.utc(f.date.year, f.date.month, f.date.day);
    return !d.isBefore(startDay) && !d.isAfter(endDay);
  }).toList();

  final filteredExpenses = expenses.where((x) {
    final d = DateTime.utc(x.date.year, x.date.month, x.date.day);
    return !d.isBefore(startDay) && !d.isAfter(endDay);
  }).toList();

  // Totais monetários.
  final fuelSpent = filteredFuels.fold(
    Decimal.zero,
    (acc, f) => acc + f.totalCost,
  );
  final expensesSpent = filteredExpenses.fold(
    Decimal.zero,
    (acc, x) => acc + x.amount,
  );
  final totalSpent = fuelSpent + expensesSpent;

  // km rodados: max - min de odometer (só se >= 2 fuels no range).
  int kmDriven = 0;
  Decimal? avgConsumptionKmL;

  if (filteredFuels.length >= 2) {
    final odometers = filteredFuels.map((f) => f.odometer).toList();
    final maxOdo = odometers.reduce((a, b) => a > b ? a : b);
    final minOdo = odometers.reduce((a, b) => a < b ? a : b);
    kmDriven = maxOdo - minOdo;

    if (kmDriven > 0) {
      final totalLiters = filteredFuels.fold(
        Decimal.zero,
        (acc, f) => acc + f.liters,
      );
      if (totalLiters > Decimal.zero) {
        // km / liters com precisão decimal (4 casas).
        final ratio = (Decimal.fromInt(kmDriven) / totalLiters).toDecimal(
          scaleOnInfinitePrecision: 5,
        );
        avgConsumptionKmL = ratio.round(scale: 4);
      }
    }
  }

  // Dias: diferença inclusiva.
  final days = endDay.difference(startDay).inDays + 1;

  return TripStats(
    fuelCount: filteredFuels.length,
    expenseCount: filteredExpenses.length,
    fuelSpent: fuelSpent,
    expensesSpent: expensesSpent,
    totalSpent: totalSpent,
    kmDriven: kmDriven,
    avgConsumptionKmL: avgConsumptionKmL,
    days: days,
  );
}
