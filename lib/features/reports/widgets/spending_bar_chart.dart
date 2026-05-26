// Gráfico de barras para gasto mensal em R$.
//
// Design:
// - Barras na cor brand com bordas arredondadas no topo.
// - Barra do mês corrente em accent (lima) para destacar contexto.
// - Grid horizontal suave em hairline; sem borda/frame externo.
// - Labels X: mês abreviado PT-BR. Labels Y: R$ compacto.
// - ANIMAÇÃO: swapAnimationDuration 800ms easeOutCubic (fl_chart built-in).
//   Ao entrar, barras crescem do zero. Ao dados mudarem, re-animam.

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/features/reports/monthly_spending.dart';
import 'package:autolog/features/reports/reports_helpers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SpendingBarChart extends StatelessWidget {
  const SpendingBarChart({super.key, required this.data});

  final List<MonthlyTotal> data;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentBucket = DateTime.utc(now.year, now.month, 1);

    // Conversão Decimal→double APENAS na borda de display (BarChartGroupData).
    final groups = [
      for (var i = 0; i < data.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: data[i].total.toDouble(),
              width: _barWidth(data.length),
              color: data[i].month == currentBucket
                  ? AppColors.accent
                  : AppColors.brand,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              // Back-ground rod suave mostra "espaço" disponível
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: _maxY(data) * 1.1,
                color: AppColors.surfaceSunken,
              ),
            ),
          ],
        ),
    ];

    final maxY = _maxY(data) * 1.1;
    final fmt = NumberFormat.compactCurrency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 0,
    );

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.hairline,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceInverse,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = data[group.x];
                final label = formatMonthLabel(item.month);
                final value = NumberFormat.currency(
                  locale: 'pt_BR',
                  symbol: r'R$',
                  decimalDigits: 2,
                ).format(rod.toY);
                return BarTooltipItem(
                  '$label\n$value',
                  AppTypography.body(
                    12,
                    weight: FontWeight.w600,
                    color: AppColors.brandInk,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      fmt.format(value),
                      style: AppTypography.body(10, color: AppColors.inkSoft),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  // Mostra a cada 2 meses se tiver mais de 6
                  if (data.length > 6 && index % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _shortMonth(data[index].month),
                      style: AppTypography.body(
                        10,
                        color: data[index].month == currentBucket
                            ? AppColors.brand
                            : AppColors.inkSoft,
                        weight: data[index].month == currentBucket
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  double _barWidth(int count) {
    if (count <= 3) return 28;
    if (count <= 6) return 22;
    if (count <= 9) return 16;
    return 12;
  }

  double _maxY(List<MonthlyTotal> data) {
    if (data.isEmpty) return 100;
    final max = data
        .map((d) => d.total.toDouble())
        .reduce((a, b) => a > b ? a : b);
    return max == 0 ? 100 : max;
  }

  /// Mês no formato "mai" (3 letras PT-BR sem ponto).
  String _shortMonth(DateTime dt) {
    const names = [
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
    return names[dt.month - 1];
  }
}
