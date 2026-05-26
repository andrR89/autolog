import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

/// Resultado do consumo médio por tipo de combustível (km/L).
class FuelEconomy {
  const FuelEconomy({required this.kmPerLiter, required this.basedOnEntries});

  final Decimal kmPerLiter;
  final int basedOnEntries;
}

/// Resultado da comparação de custo por km entre gasolina e etanol.
class FuelComparison {
  const FuelComparison({
    required this.gasolinaCostPerKm,
    required this.etanolCostPerKm,
    required this.bestChoice,
    required this.savingsPercent,
  });

  final Decimal gasolinaCostPerKm;
  final Decimal etanolCostPerKm;

  /// Combustível mais barato por km rodado.
  final FuelType bestChoice;

  /// Percentual de economia ao usar [bestChoice] vs o pior. Escala 1 casa decimal.
  final Decimal savingsPercent;
}

// Fallback para veículos sem histórico suficiente (carros flex modernos).
const _genericGasolinaKmL = '12';
const _genericEtanolKmL = '8.4';

/// Calcula consumo médio por tipo de combustível a partir do histórico.
///
/// Usa a abordagem cheio-a-cheio: filtra [entries] pelo [type] e ordena por
/// data ASC. Para cada par consecutivo, consumo = (odômetro2 − odômetro1) /
/// litros2. Retorna a média desses valores.
///
/// Retorna null se houver menos de 2 abastecimentos do tipo (sem baseline).
FuelEconomy? computeFuelEconomy(List<FuelEntry> entries, FuelType type) {
  // Filtra pelo tipo e ordena por data ASC.
  final filtered = entries.where((e) => e.fuelType == type).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  if (filtered.length < 2) return null;

  // Calcula km/L para cada par consecutivo.
  final ratios = <Decimal>[];
  for (var i = 1; i < filtered.length; i++) {
    final prev = filtered[i - 1];
    final curr = filtered[i];
    final distKm = curr.odometer - prev.odometer;
    if (distKm <= 0) continue;
    final kmPerLiter = (Decimal.fromInt(distKm) / curr.liters)
        .toDecimal(scaleOnInfinitePrecision: 5)
        .round(scale: 4);
    ratios.add(kmPerLiter);
  }

  if (ratios.isEmpty) return null;

  // Média dos pares.
  var sum = Decimal.zero;
  for (final r in ratios) {
    sum = sum + r;
  }
  final avg = (sum / Decimal.fromInt(ratios.length))
      .toDecimal(scaleOnInfinitePrecision: 5)
      .round(scale: 4);

  return FuelEconomy(
    kmPerLiter: avg,
    basedOnEntries: filtered.length,
  );
}

/// Extrai o último preço por litro registrado para [type], ordenando por data
/// desc. Retorna null se não houver nenhum entry do tipo.
Decimal? lastPriceFor(List<FuelEntry> entries, FuelType type) {
  final filtered = entries.where((e) => e.fuelType == type).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  if (filtered.isEmpty) return null;
  return filtered.first.pricePerLiter;
}

/// Compara o custo por km de gasolina e etanol.
///
/// Usa o consumo real do histórico quando disponível; recorre ao fallback
/// genérico (gasolina 12 km/L, etanol 8,4 km/L) quando não há dados.
FuelComparison compareFuels({
  required Decimal gasolinaPricePerLiter,
  required Decimal etanolPricePerLiter,
  required List<FuelEntry> historicalEntries,
}) {
  final gKmL =
      computeFuelEconomy(historicalEntries, FuelType.gasolina)?.kmPerLiter ??
          Decimal.parse(_genericGasolinaKmL);
  final eKmL =
      computeFuelEconomy(historicalEntries, FuelType.etanol)?.kmPerLiter ??
          Decimal.parse(_genericEtanolKmL);

  final gCostPerKm = (gasolinaPricePerLiter / gKmL)
      .toDecimal(scaleOnInfinitePrecision: 5)
      .round(scale: 4);
  final eCostPerKm = (etanolPricePerLiter / eKmL)
      .toDecimal(scaleOnInfinitePrecision: 5)
      .round(scale: 4);

  final best =
      eCostPerKm < gCostPerKm ? FuelType.etanol : FuelType.gasolina;
  final worstCost = best == FuelType.etanol ? gCostPerKm : eCostPerKm;
  final bestCost = best == FuelType.etanol ? eCostPerKm : gCostPerKm;

  // savings = (worst − best) / worst × 100, arredondado a 1 casa decimal.
  // Note: Decimal / Decimal returns Rational — call toDecimal() before *100.
  final savings = worstCost == Decimal.zero
      ? Decimal.zero
      : (((worstCost - bestCost) / worstCost)
              .toDecimal(scaleOnInfinitePrecision: 5) *
          Decimal.fromInt(100))
          .round(scale: 1);

  return FuelComparison(
    gasolinaCostPerKm: gCostPerKm,
    etanolCostPerKm: eCostPerKm,
    bestChoice: best,
    savingsPercent: savings,
  );
}
