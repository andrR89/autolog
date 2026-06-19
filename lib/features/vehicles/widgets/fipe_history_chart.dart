import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/fipe_history_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Card que exibe o histórico de valor FIPE de um veículo ao longo do tempo.
///
/// - 0 pontos: empty state discreto.
/// - 1 ponto: exibe o valor único com data.
/// - 2+ pontos: LineChart com fl_chart.
/// - 13+ pontos: badge YoY (delta percentual entre valor mais recente e ~12 meses atrás).
class FipeHistoryChart extends ConsumerWidget {
  const FipeHistoryChart({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(fipeHistoryProvider(vehicleId));

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (snapshots) => _FipeHistoryCard(snapshots: snapshots),
    );
  }
}

class _FipeHistoryCard extends StatelessWidget {
  const _FipeHistoryCard({required this.snapshots});

  final List<FipeSnapshot> snapshots;

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
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (snapshots.isEmpty) {
      return _EmptyState();
    }

    if (snapshots.length == 1) {
      return _SinglePointState(snapshot: snapshots.first);
    }

    // 2+ pontos: gráfico
    final yoyBadge = snapshots.length >= 13 ? _computeYoY() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Valor FIPE',
              style: AppTypography.display(
                15,
                weight: FontWeight.w600,
                color: context.ink,
              ),
            ),
            const Spacer(),
            if (yoyBadge != null) _YoYBadge(delta: yoyBadge),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${snapshots.length} pontos coletados',
          style: TextStyle(fontSize: 12, color: context.inkMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 180,
          child: _LineChart(snapshots: snapshots),
        ),
      ],
    );
  }

  /// Calcula delta YoY: valor mais recente vs snapshot ~12 posições atrás.
  double _computeYoY() {
    final recent = snapshots.last;
    final older = snapshots[snapshots.length - 13];
    if (older.value == Decimal.zero) return 0;
    final delta = (recent.value - older.value) / older.value;
    return delta.toDouble() * 100;
  }
}

// ---------------------------------------------------------------------------
// Estado: 0 pontos
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.show_chart, color: context.inkSoft, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Valor FIPE — atualize no cadastro pra começar o histórico',
            style: TextStyle(fontSize: 13, color: context.inkMuted),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Estado: 1 ponto
// ---------------------------------------------------------------------------

class _SinglePointState extends StatelessWidget {
  const _SinglePointState({required this.snapshot});

  final FipeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    // FIPE sem centavos (R$ 39.978) — alinha com o card da garagem.
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 0,
    );
    final formatted = fmt.format(snapshot.value.toDouble());
    final monthLabel = _monthShortPtBr(snapshot.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Valor FIPE',
          style: AppTypography.display(
            15,
            weight: FontWeight.w600,
            color: context.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          formatted,
          style: AppTypography.display(
            22,
            weight: FontWeight.w700,
            color: context.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '1 ponto coletado em $monthLabel',
          style: TextStyle(fontSize: 12, color: context.inkMuted),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// LineChart
// ---------------------------------------------------------------------------

class _LineChart extends StatelessWidget {
  const _LineChart({required this.snapshots});

  final List<FipeSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final spots = snapshots.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();
    final inkMuted = context.inkMuted;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: _xInterval(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= snapshots.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _monthShortPtBr(snapshots[idx].month),
                    style: TextStyle(
                      fontSize: 10,
                      color: inkMuted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.brand,
            barWidth: 2,
            dotData: FlDotData(
              show: snapshots.length <= 6,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.brand.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final idx = s.spotIndex;
                final snap = snapshots[idx];
                final fmt = NumberFormat.currency(
                  locale: 'pt_BR',
                  symbol: r'R$',
                  decimalDigits: 0,
                );
                return LineTooltipItem(
                  '${_monthShortPtBr(snap.month)}\n${fmt.format(snap.value.toDouble())}',
                  const TextStyle(
                    color: AppColors.brandInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _xInterval() {
    if (snapshots.length <= 6) return 1;
    if (snapshots.length <= 12) return 2;
    return 3;
  }
}

// ---------------------------------------------------------------------------
// Badge YoY
// ---------------------------------------------------------------------------

class _YoYBadge extends StatelessWidget {
  const _YoYBadge({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final isPositive = delta >= 0;
    final color = isPositive ? AppColors.success : AppColors.danger;
    final bgColor = isPositive ? AppColors.successSoft : AppColors.dangerSoft;
    final sign = isPositive ? '+' : '';
    final label = '$sign${delta.toStringAsFixed(1).replaceAll('.', ',')}%';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper: converte "YYYY-MM" para label curto pt-BR ("jan/26")
// ---------------------------------------------------------------------------

String _monthShortPtBr(String yyyymm) {
  const m = [
    '',
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  final parts = yyyymm.split('-');
  if (parts.length != 2) return yyyymm;
  final mi = int.tryParse(parts[1]);
  if (mi == null || mi < 1 || mi > 12) return yyyymm;
  return '${m[mi]}/${parts[0].substring(2)}';
}
