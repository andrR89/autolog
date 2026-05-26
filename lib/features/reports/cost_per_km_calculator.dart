import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

/// Resultado do cálculo de custo por km para um conjunto de abastecimentos
/// e despesas.
class CostMetrics {
  const CostMetrics({
    required this.totalKm,
    required this.fuelCost,
    required this.otherCost,
    required this.totalCost,
    required this.fuelCostPerKm,
    required this.totalCostPerKm,
  });

  /// km percorridos = max(odometer) - min(odometer) das fuel entries.
  /// 0 se houver < 2 entries.
  final int totalKm;

  /// Soma de [FuelEntry.totalCost] nas entries fornecidas.
  final Decimal fuelCost;

  /// Soma de [Expense.amount] nas expenses fornecidas.
  final Decimal otherCost;

  /// [fuelCost] + [otherCost].
  final Decimal totalCost;

  /// [fuelCost] / [totalKm], arredondado a 4 casas. null se [totalKm] == 0.
  final Decimal? fuelCostPerKm;

  /// [totalCost] / [totalKm], arredondado a 4 casas. null se [totalKm] == 0.
  final Decimal? totalCostPerKm;
}

/// Computa custo por km para uma janela de [fuels]/[expenses].
///
/// - [totalKm] = max(odometer) − min(odometer) das fuel entries; 0 se < 2.
/// - Despesas entram apenas no custo total, nunca no totalKm.
/// - Divisão usa [toDecimal(scaleOnInfinitePrecision: 5)].round(scale: 4).
CostMetrics computeCostMetrics({
  required List<FuelEntry> fuels,
  required List<Expense> expenses,
}) {
  // --- totalKm ---
  int totalKm = 0;
  if (fuels.length >= 2) {
    var minOdo = fuels.first.odometer;
    var maxOdo = fuels.first.odometer;
    for (final f in fuels) {
      if (f.odometer < minOdo) minOdo = f.odometer;
      if (f.odometer > maxOdo) maxOdo = f.odometer;
    }
    totalKm = maxOdo - minOdo;
  }

  // --- fuelCost ---
  var fuelCost = Decimal.zero;
  for (final f in fuels) {
    fuelCost = fuelCost + f.totalCost;
  }

  // --- otherCost ---
  var otherCost = Decimal.zero;
  for (final x in expenses) {
    otherCost = otherCost + x.amount;
  }

  final totalCost = fuelCost + otherCost;

  // --- perKm ---
  Decimal? fuelCostPerKm;
  Decimal? totalCostPerKm;
  if (totalKm > 0) {
    final kmDecimal = Decimal.fromInt(totalKm);
    fuelCostPerKm = (fuelCost / kmDecimal)
        .toDecimal(scaleOnInfinitePrecision: 5)
        .round(scale: 4);
    totalCostPerKm = (totalCost / kmDecimal)
        .toDecimal(scaleOnInfinitePrecision: 5)
        .round(scale: 4);
  }

  return CostMetrics(
    totalKm: totalKm,
    fuelCost: fuelCost,
    otherCost: otherCost,
    totalCost: totalCost,
    fuelCostPerKm: fuelCostPerKm,
    totalCostPerKm: totalCostPerKm,
  );
}
