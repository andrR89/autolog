// Providers Riverpod para CO₂ — Sprint 6.CC.
//
// Arquitetura:
//   co2ForMonthProvider.family(vehicleId, ano, mês)
//     → filtra os abastecimentos do veículo pelo mês/ano e computa Co2Result.
//   co2ForYearProvider.family(vehicleId)
//     → filtra pelo ano corrente e computa Co2Result.
//
// Ambos são derivados do stream reativo existente (fuelEntriesByVehicleProvider)
// e do cálculo de odômetro do período.

import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/insights/co2/co2_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Args imutável para o provider mensal (vehicleId + ano + mês)
// ---------------------------------------------------------------------------

/// Argumento do provider mensal: identifica veículo + mês/ano.
class Co2MonthArgs {
  const Co2MonthArgs({
    required this.vehicleId,
    required this.year,
    required this.month,
  });

  final String vehicleId;
  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Co2MonthArgs &&
          vehicleId == other.vehicleId &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => Object.hash(vehicleId, year, month);
}

// ---------------------------------------------------------------------------
// co2ForMonthProvider
// ---------------------------------------------------------------------------

/// Emissão de CO₂ para um mês específico do veículo.
///
/// - Filtra [entries] pelo (year, month).
/// - [totalKmInPeriod]: diferença entre o maior e o menor odômetro
///   nos abastecimentos do mês (aproximação — não considera leituras
///   fora do período; exibe null se apenas 1 entry no mês).
/// - Reativo ao stream de abastecimentos (Drift watch).
final co2ForMonthProvider =
    Provider.family<AsyncValue<Co2Result>, Co2MonthArgs>((ref, args) {
      final entriesAsync = ref.watch(
        fuelEntriesByVehicleProvider(args.vehicleId),
      );

      return entriesAsync.whenData((entries) {
        final monthEntries = entries
            .where(
              (e) => e.date.year == args.year && e.date.month == args.month,
            )
            .toList();

        // Calcula distância percorrida no período pelo delta de odômetro.
        int totalKm = 0;
        if (monthEntries.length >= 2) {
          final sorted = List.of(monthEntries)
            ..sort((a, b) => a.odometer.compareTo(b.odometer));
          totalKm = sorted.last.odometer - sorted.first.odometer;
        }

        return computeCo2(entries: monthEntries, totalKmInPeriod: totalKm);
      });
    });

// ---------------------------------------------------------------------------
// co2ForYearProvider
// ---------------------------------------------------------------------------

/// Emissão de CO₂ acumulada no ano corrente para o veículo.
///
/// - Filtra pelo ano atual (DateTime.now().year).
/// - [totalKmInPeriod]: delta de odômetro dos abastecimentos do ano.
/// - Reativo ao stream de abastecimentos.
final co2ForYearProvider = Provider.family<AsyncValue<Co2Result>, String>((
  ref,
  vehicleId,
) {
  final entriesAsync = ref.watch(fuelEntriesByVehicleProvider(vehicleId));

  return entriesAsync.whenData((entries) {
    final currentYear = DateTime.now().year;
    final yearEntries = entries
        .where((e) => e.date.year == currentYear)
        .toList();

    int totalKm = 0;
    if (yearEntries.length >= 2) {
      final sorted = List.of(yearEntries)
        ..sort((a, b) => a.odometer.compareTo(b.odometer));
      totalKm = sorted.last.odometer - sorted.first.odometer;
    }

    return computeCo2(entries: yearEntries, totalKmInPeriod: totalKm);
  });
});
