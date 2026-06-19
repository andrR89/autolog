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
///
/// [vehicleInitialOdometer] é usado como segundo ponto pra calcular
/// km no período quando há apenas 1 abastecimento (caso comum: usuário
/// novo). Sem isso, gCO₂/km cairia em "—" sempre que o mês tem 1 entry.
class Co2MonthArgs {
  const Co2MonthArgs({
    required this.vehicleId,
    required this.year,
    required this.month,
    this.vehicleInitialOdometer,
  });

  final String vehicleId;
  final int year;
  final int month;
  final int? vehicleInitialOdometer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Co2MonthArgs &&
          vehicleId == other.vehicleId &&
          year == other.year &&
          month == other.month &&
          vehicleInitialOdometer == other.vehicleInitialOdometer;

  @override
  int get hashCode =>
      Object.hash(vehicleId, year, month, vehicleInitialOdometer);
}

/// Argumento do provider anual: vehicleId + odômetro inicial (opcional)
/// usado quando há apenas 1 abastecimento no ano.
class Co2YearArgs {
  const Co2YearArgs({
    required this.vehicleId,
    this.vehicleInitialOdometer,
  });

  final String vehicleId;
  final int? vehicleInitialOdometer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Co2YearArgs &&
          vehicleId == other.vehicleId &&
          vehicleInitialOdometer == other.vehicleInitialOdometer;

  @override
  int get hashCode => Object.hash(vehicleId, vehicleInitialOdometer);
}

/// Calcula `totalKmInPeriod` a partir das entries do período + um possível
/// odômetro inicial do veículo (fallback quando há apenas 1 entry).
int computePeriodKm(List<dynamic> entries, int? vehicleInitialOdometer) {
  if (entries.length >= 2) {
    final sorted = List.of(entries)
      ..sort(
        (a, b) => (a.odometer as int).compareTo(b.odometer as int),
      );
    return (sorted.last.odometer as int) - (sorted.first.odometer as int);
  }
  if (entries.length == 1 && vehicleInitialOdometer != null) {
    final delta = (entries.first.odometer as int) - vehicleInitialOdometer;
    if (delta > 0) return delta;
  }
  return 0;
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

        final totalKm = computePeriodKm(
          monthEntries,
          args.vehicleInitialOdometer,
        );

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
final co2ForYearProvider =
    Provider.family<AsyncValue<Co2Result>, Co2YearArgs>((ref, args) {
      final entriesAsync = ref.watch(
        fuelEntriesByVehicleProvider(args.vehicleId),
      );

      return entriesAsync.whenData((entries) {
        final currentYear = DateTime.now().year;
        final yearEntries = entries
            .where((e) => e.date.year == currentYear)
            .toList();

        final totalKm = computePeriodKm(
          yearEntries,
          args.vehicleInitialOdometer,
        );

        return computeCo2(entries: yearEntries, totalKmInPeriod: totalKm);
      });
    });
