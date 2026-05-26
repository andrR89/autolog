import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:decimal/decimal.dart';

/// Resultado do cálculo de consumo para uma entry específica.
class ConsumptionRow {
  const ConsumptionRow({required this.entry, this.kmPerLiter, this.costPerKm});

  final FuelEntry entry;

  /// km/l da janela que fecha NESTA entry (ou null se não fecha ciclo).
  final Decimal? kmPerLiter;

  /// custo/km da mesma janela (ou null).
  final Decimal? costPerKm;
}

/// Recebe entries do mesmo veículo, ordenados por data ascendente.
/// Retorna uma lista de mesma length, na mesma ordem.
///
/// Regras (PRD §7 + spec sprint-2.2):
/// - Primeiro cheio (sem baseline anterior) → null.
/// - Parcial sem cheio anterior → null.
/// - Cheio com cheio anterior → calcula janela (do cheio anterior exclusivo até
///   este cheio inclusivo): km = odômetro atual − odômetro do último cheio;
///   litros = soma de liters da janela; custo = soma de totalCost da janela.
/// - Se km <= 0 ou litros <= 0 → null (defensivo, nunca lança exceção).
/// - Parciais dentro de uma janela sempre recebem null.
List<ConsumptionRow> computeConsumption(List<FuelEntry> entriesAsc) {
  if (entriesAsc.isEmpty) return [];

  final result = <ConsumptionRow>[];

  // Índice do último abastecimento com full_tank == true encontrado.
  // null enquanto nenhum cheio foi visto ainda.
  int? lastFullIndex;

  for (int i = 0; i < entriesAsc.length; i++) {
    final current = entriesAsc[i];
    Decimal? kmPerLiter;
    Decimal? costPerKm;

    if (current.fullTank && lastFullIndex != null) {
      // Janela: do lastFullIndex+1 até i (inclusivo).
      final window = entriesAsc.sublist(lastFullIndex + 1, i + 1);

      final km = current.odometer - entriesAsc[lastFullIndex].odometer;

      // Soma de litros e custo da janela usando Decimal (NUNCA double).
      var litros = Decimal.zero;
      var custoJanela = Decimal.zero;
      for (final e in window) {
        litros = litros + e.liters;
        custoJanela = custoJanela + e.totalCost;
      }

      if (km > 0 && litros > Decimal.zero) {
        final kmDecimal = Decimal.fromInt(km);
        // Use scaleOnInfinitePrecision for repeating decimals, then round to
        // exactly 4 decimal places (half-up) to ensure consistent scale for
        // both finite and infinite-precision results.
        kmPerLiter = (kmDecimal / litros)
            .toDecimal(scaleOnInfinitePrecision: 4)
            .round(scale: 4);
        costPerKm = (custoJanela / kmDecimal)
            .toDecimal(scaleOnInfinitePrecision: 4)
            .round(scale: 4);
      }
      // km <= 0 ou litros <= 0 → mantém null (defensivo).
    }

    // Independentemente de ter calculado, se é cheio atualiza o baseline.
    if (current.fullTank) {
      lastFullIndex = i;
    }

    result.add(
      ConsumptionRow(
        entry: current,
        kmPerLiter: kmPerLiter,
        costPerKm: costPerKm,
      ),
    );
  }

  return result;
}

/// Retorna true se [candidate] é monotonicamente crescente em relação ao
/// [previous] (>=). [previous] == null significa "primeiro registro" → sempre true.
/// A UI usa para AVISAR (não bloquear).
bool isOdometerMonotonic({required int candidate, required int? previous}) {
  if (previous == null) return true;
  return candidate >= previous;
}
