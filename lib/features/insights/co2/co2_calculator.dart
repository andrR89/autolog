// Calculadora de emissão de CO₂ — Sprint 6.CC.
//
// Fatores de emissão (kg CO₂ / litro queimado):
//   Gasolina C (com etanol anidro 27%): 2,21 kg/L
//     Fonte: CONAMA Res. 18/86 + IPCC 2006 GL v4, Tabela 2.2 (fator ponderado
//     para blend E27 vigente no Brasil em 2025).
//   Etanol hidratado: 1,52 kg/L (combustão direta)
//     Fonte: RENOVABIO/EPE — apenas queima, sem ciclo de vida da cana.
//   Diesel B (com biodiesel 14%): 2,68 kg/L
//     Fonte: IBAMA/MCTI — blend B14 vigente 2024-2025.
//   GNV: 1,93 kg/L equivalente (2,75 kg/m³ → ÷ ~1,424 densidade relativa L)
//     Fonte: IPCC 2006 GL, Tabela 2.3 (natural gas, spark-ignition).
//   Flex sem contexto de mix: fallback gasolina (conservador).
//
// Nota sobre etanol: o app exibe apenas a queima direta do combustível.
// O ciclo de vida completo (ex.: sequestro de carbono da cana) não é exibido.
//
// Equivalência árvores: 1 árvore adulta absorve ≈21 kg CO₂/ano
// (média IPCC Working Group III, baseada em árvore tropical de porte médio).

import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

// ---------------------------------------------------------------------------
// Fatores de emissão
// ---------------------------------------------------------------------------

/// Retorna o fator de emissão em kg CO₂ / litro para o [FuelType] dado.
///
/// Combustíveis "flex" não carregam informação de mix real — usamos o fator
/// da gasolina como fallback conservador e registramos no [Co2Result.unknownFuelTypes].
Decimal emissionFactor(FuelType type) {
  switch (type) {
    case FuelType.gasolina:
      return Decimal.parse('2.21');
    case FuelType.etanol:
      return Decimal.parse('1.52');
    case FuelType.diesel:
      return Decimal.parse('2.68');
    case FuelType.gnv:
      return Decimal.parse('1.93');
    case FuelType.flex:
      // Fallback conservador — sem contexto de mix real, assume gasolina.
      return Decimal.parse('2.21');
  }
}

/// Tipos que usaram fallback durante o cálculo (nome wire → contagem).
/// Permite à UI/alertas informar o usuário sobre a aproximação.
const _fallbackTypes = {FuelType.flex};

// ---------------------------------------------------------------------------
// Co2Result
// ---------------------------------------------------------------------------

/// Resultado do cálculo de emissão de CO₂ para um conjunto de abastecimentos.
class Co2Result {
  const Co2Result({
    required this.totalKg,
    required this.perKmGrams,
    required this.periodDays,
    required this.entriesCount,
    required this.treesEquivalentYear,
    this.unknownFuelTypes = const {},
  });

  /// Total de CO₂ emitido em kg (precisão Decimal; nunca double).
  final Decimal totalKg;

  /// gCO₂/km — null se [totalKmInPeriod] == 0 (baseline insuficiente).
  final Decimal? perKmGrams;

  /// Dias de cobertura: diferença entre o abastecimento mais antigo e o
  /// mais recente na lista. Zero se houver apenas um abastecimento.
  final int periodDays;

  /// Quantidade de abastecimentos considerados.
  final int entriesCount;

  /// Estimativa de árvores adultas necessárias para absorver [totalKg] em 1 ano.
  /// Fórmula: floor(totalKg / 21). Baseado em ≈21 kg CO₂/ano por árvore tropical.
  final int treesEquivalentYear;

  /// Tipos de combustível que usaram fator de fallback (gasolina), mapeados
  /// para a quantidade de abastecimentos afetados.
  /// Vazio → nenhum fallback foi necessário.
  final Map<String, int> unknownFuelTypes;
}

// ---------------------------------------------------------------------------
// computeCo2
// ---------------------------------------------------------------------------

/// Computa a emissão de CO₂ para um conjunto de [entries] e um período
/// de distância [totalKmInPeriod].
///
/// Invariantes:
/// - [totalKg] = Σ(liters × emissionFactor(fuelType))
/// - [perKmGrams] = (totalKg × 1000) / totalKmInPeriod   (null se km ≤ 0)
/// - Tipos com fallback → registrados em [Co2Result.unknownFuelTypes]
/// - Nunca lança; tipos desconhecidos não crasham.
Co2Result computeCo2({
  required List<FuelEntry> entries,
  required int totalKmInPeriod,
}) {
  if (entries.isEmpty) {
    return Co2Result(
      totalKg: Decimal.zero,
      perKmGrams: null,
      periodDays: 0,
      entriesCount: 0,
      treesEquivalentYear: 0,
    );
  }

  var totalKg = Decimal.zero;
  final unknownFuelTypes = <String, int>{};

  for (final entry in entries) {
    totalKg += entry.liters * emissionFactor(entry.fuelType);

    if (_fallbackTypes.contains(entry.fuelType)) {
      final key = entry.fuelType.wire;
      unknownFuelTypes[key] = (unknownFuelTypes[key] ?? 0) + 1;
    }
  }

  // perKmGrams — null se km ≤ 0 (Regra de Ouro: nunca exibir cálculo sem baseline)
  Decimal? perKmGrams;
  if (totalKmInPeriod > 0) {
    // totalKg * 1000 / km  →  g CO₂/km
    final grams = totalKg * Decimal.fromInt(1000);
    final km = Decimal.fromInt(totalKmInPeriod);
    perKmGrams = (grams / km).toDecimal(scaleOnInfinitePrecision: 10);
  }

  // periodDays entre o abastecimento mais antigo e o mais recente.
  int periodDays = 0;
  if (entries.length > 1) {
    DateTime minDate = entries.first.date;
    DateTime maxDate = entries.first.date;
    for (final e in entries) {
      if (e.date.isBefore(minDate)) minDate = e.date;
      if (e.date.isAfter(maxDate)) maxDate = e.date;
    }
    periodDays = maxDate.difference(minDate).inDays;
  }

  // treesEquivalentYear: floor(totalKg / 21)
  final trees = (totalKg / Decimal.fromInt(21))
      .toDecimal(scaleOnInfinitePrecision: 0)
      .toBigInt()
      .toInt();

  return Co2Result(
    totalKg: totalKg,
    perKmGrams: perKmGrams,
    periodDays: periodDays,
    entriesCount: entries.length,
    treesEquivalentYear: trees,
    unknownFuelTypes: unknownFuelTypes,
  );
}
