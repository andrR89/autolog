import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/expenses/expenses_list_screen.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/reports/cost_per_km_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Card de custo por km para um veículo.
///
/// Mostra fuelCostPerKm e totalCostPerKm calculados sobre todos os
/// abastecimentos e despesas do veículo. Empty state se < 2 fuels.
class CostPerKmCard extends ConsumerWidget {
  const CostPerKmCard({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelsAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));
    final expensesAsync = ref.watch(expensesByVehicleProvider(vehicle.id));

    return fuelsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (fuels) => expensesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (expenses) => _CostPerKmContent(
          vehicle: vehicle,
          metrics: computeCostMetrics(fuels: fuels, expenses: expenses),
          fuelCount: fuels.length,
        ),
      ),
    );
  }
}

class _CostPerKmContent extends StatelessWidget {
  const _CostPerKmContent({
    required this.vehicle,
    required this.metrics,
    required this.fuelCount,
  });

  final Vehicle vehicle;
  final CostMetrics metrics;
  final int fuelCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.surfaceRaised,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: context.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: fuelCount < 2 ? _buildEmpty(context) : _buildData(context),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Eyebrow('CUSTO POR KM'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cadastre mais abastecimentos pra calcular o custo por km.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.inkMuted),
        ),
      ],
    );
  }

  Widget _buildData(BuildContext context) {
    final currFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );

    final fuelLabel = metrics.fuelCostPerKm != null
        ? '${currFmt.format(metrics.fuelCostPerKm!.toDouble())}/km'
        : '—';
    final totalLabel = metrics.totalCostPerKm != null
        ? '${currFmt.format(metrics.totalCostPerKm!.toDouble())}/km'
        : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Eyebrow('CUSTO POR KM'),
        const SizedBox(height: AppSpacing.sm),
        _MetricRow(label: 'Combustível', value: fuelLabel),
        const SizedBox(height: AppSpacing.xs),
        _MetricRow(label: 'Total', value: totalLabel),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Baseado em $fuelCount abastecimentos · ${metrics.totalKm} km',
          style: TextStyle(fontSize: 12, color: context.inkMuted),
        ),
      ],
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
        color: context.inkMuted,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTypography.body(14, color: context.inkMuted),
        ),
        Text(value, style: AppTypography.metric(18)),
      ],
    );
  }
}
