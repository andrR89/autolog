import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/reports/co2_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card de pegada de carbono para o ano corrente.
///
/// Lê os abastecimentos do veículo, filtra pelo ano corrente e exibe o total
/// de CO₂ emitido e a equivalência em árvores absorvendo por 1 ano.
/// Omitido (SizedBox.shrink) se não houver abastecimentos no ano corrente.
class Co2Card extends ConsumerWidget {
  const Co2Card({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelsAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));

    return fuelsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (fuels) {
        final currentYear = DateTime.now().year;
        final yearEntries = fuels
            .where((e) => e.date.year == currentYear)
            .toList();

        if (yearEntries.isEmpty) return const SizedBox.shrink();

        final result = computeCo2(entries: yearEntries);
        return _Co2Content(year: currentYear, result: result);
      },
    );
  }
}

class _Co2Content extends StatelessWidget {
  const _Co2Content({required this.year, required this.result});

  final int year;
  final Co2Result result;

  @override
  Widget build(BuildContext context) {
    // Formata o total em kg com 2 casas decimais (ex.: 92,40 kg)
    final kgFormatted = result.totalKg.toStringAsFixed(2).replaceAll('.', ',');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Eyebrow('PEGADA DE CARBONO'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '🌱 $kgFormatted kg CO₂ em $year',
                style: AppTypography.metric(22, color: AppColors.success),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '≈ ${result.treesEquivalentYear} árvores absorvendo por 1 ano',
                style: AppTypography.body(13, color: AppColors.success),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.success,
        letterSpacing: 1.4,
      ),
    );
  }
}
