import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

/// Resultado do cálculo de pegada de carbono para um conjunto de abastecimentos.
class Co2Result {
  const Co2Result({
    required this.totalKg,
    required this.treesEquivalentYear,
  });

  /// Total de CO₂ emitido em kg (precisão Decimal).
  final Decimal totalKg;

  /// Equivalência em árvores absorvendo CO₂ por 1 ano.
  /// Fórmula: floor(totalKg / 22) — 1 árvore absorve ~22 kg CO₂/ano.
  final int treesEquivalentYear;
}

/// Fator de emissão de CO₂ em kg por litro para cada tipo de combustível.
///
/// Fontes: IPCC 2006 Tier 1.
/// GNV: 1.93 kg/m³ tratado como L por simplicidade.
/// Flex: usa fator conservador (gasolina) quando não há contexto de mix.
Decimal kgCo2PerLiter(FuelType type) {
  switch (type) {
    case FuelType.gasolina:
      return Decimal.parse('2.31');
    case FuelType.etanol:
      return Decimal.parse('1.51');
    case FuelType.diesel:
      return Decimal.parse('2.68');
    case FuelType.gnv:
      return Decimal.parse('1.93');
    case FuelType.flex:
      return Decimal.parse('2.31'); // conservador
  }
}

/// Computa a pegada de carbono para uma lista de abastecimentos.
///
/// - [totalKg]: soma de `liters * kgCo2PerLiter(fuelType)` para cada entry.
/// - [treesEquivalentYear]: floor(totalKg / 22).
/// - Lista vazia → zero kg, 0 árvores.
Co2Result computeCo2({required List<FuelEntry> entries}) {
  var total = Decimal.zero;
  for (final e in entries) {
    total += e.liters * kgCo2PerLiter(e.fuelType);
  }

  final trees = (total / Decimal.fromInt(22))
      .toDecimal(scaleOnInfinitePrecision: 0)
      .toBigInt()
      .toInt();

  return Co2Result(totalKg: total, treesEquivalentYear: trees);
}
