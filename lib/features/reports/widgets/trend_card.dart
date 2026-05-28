import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/expenses/expenses_list_screen.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/reports/trend_analyzer.dart';
import 'package:autolog/features/reports/widgets/trend_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Card de análise de tendência (consumo e gasto) para um veículo.
///
/// Compara os últimos 3 meses vs os 3 meses anteriores.
class TrendCard extends ConsumerWidget {
  const TrendCard({super.key, required this.vehicle});

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
        data: (expenses) {
          final now = DateTime.now();
          final consumptionTrend = analyzeConsumptionTrend(
            entries: fuels,
            now: now,
          );
          final spendingTrend = analyzeSpendingTrend(
            fuels: fuels,
            expenses: expenses,
            now: now,
          );

          return _TrendContent(
            consumptionTrend: consumptionTrend,
            spendingTrend: spendingTrend,
          );
        },
      ),
    );
  }
}

class _TrendContent extends StatelessWidget {
  const _TrendContent({
    required this.consumptionTrend,
    required this.spendingTrend,
  });

  final TrendAnalysis consumptionTrend;
  final TrendAnalysis spendingTrend;

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
          child: !consumptionTrend.hasEnoughData && !spendingTrend.hasEnoughData
              ? _buildEmpty(context)
              : _buildData(context),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Eyebrow('TENDÊNCIA (3 MESES)'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Dados insuficientes pra calcular tendência.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.inkMuted),
        ),
      ],
    );
  }

  Widget _buildData(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Eyebrow('TENDÊNCIA (3 MESES)'),
        const SizedBox(height: AppSpacing.sm),
        if (consumptionTrend.hasEnoughData) ...[
          _ConsumptionRow(trend: consumptionTrend),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (spendingTrend.hasEnoughData) _SpendingRow(trend: spendingTrend),
      ],
    );
  }
}

class _ConsumptionRow extends StatelessWidget {
  const _ConsumptionRow({required this.trend});

  final TrendAnalysis trend;

  @override
  Widget build(BuildContext context) {
    final prev = trend.previousValue.toDouble().toStringAsFixed(1);
    final curr = trend.currentValue.toDouble().toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.body(13, color: context.inkMuted),
              children: [
                const TextSpan(text: 'Consumo: '),
                TextSpan(
                  text:
                      '${prev.replaceAll('.', ',')} → '
                      '${curr.replaceAll('.', ',')} km/L',
                  style: AppTypography.body(
                    13,
                    weight: FontWeight.w600,
                    color: context.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TrendBadge(
          direction: trend.direction,
          deltaPercent: trend.deltaPercent,
          goodWhenDown: false, // km/L descendo = ruim
        ),
      ],
    );
  }
}

class _SpendingRow extends StatelessWidget {
  const _SpendingRow({required this.trend});

  final TrendAnalysis trend;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 0,
    );
    final prevLabel = currFmt.format(trend.previousValue.toDouble());
    final currLabel = currFmt.format(trend.currentValue.toDouble());

    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTypography.body(13, color: context.inkMuted),
              children: [
                const TextSpan(text: 'Gasto mensal médio: '),
                TextSpan(
                  text: '$prevLabel → $currLabel',
                  style: AppTypography.body(
                    13,
                    weight: FontWeight.w600,
                    color: context.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        TrendBadge(
          direction: trend.direction,
          deltaPercent: trend.deltaPercent,
          goodWhenDown: true, // gasto descendo = bom
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
