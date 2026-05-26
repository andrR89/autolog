// Gráfico de linha minimalista para preço médio por litro (R$).
//
// Design:
// - Linha em inkMuted (cinza-musgo) — reflete volatilidade de mercado
//   sem alarmismo de cor. Deixa o dado falar.
// - Sem fill (área). Sem grade vertical.
// - Pontos discretos (3px) com borda hairline.
// - Linha tracejada sutil no grid horizontal.
// - Tooltip limpo em fundo escuro.
// - ANIMAÇÃO: swapAnimationDuration 800ms easeOutCubic.

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/features/reports/monthly_price.dart';
import 'package:autolog/features/reports/reports_helpers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PriceLineChart extends StatelessWidget {
  const PriceLineChart({super.key, required this.data});

  final List<MonthlyPrice> data;

  @override
  Widget build(BuildContext context) {
    // Conversão Decimal→double APENAS na borda de display (FlSpot).
    final spots = [
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].pricePerLiter.toDouble()),
    ];

    final allValues = spots.map((s) => s.y).toList();
    final minY = allValues.isEmpty
        ? 0.0
        : allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.isEmpty
        ? 10.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final range = (maxY - minY).clamp(0.5, double.infinity);
    final chartMinY = (minY - range * 0.2).clamp(0.0, double.infinity);
    final chartMaxY = maxY + range * 0.2;

    final fmtFull = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );
    final fmtShort = NumberFormat('0.00', 'pt_BR');

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.hairline,
              strokeWidth: 1,
              dashArray: [3, 5],
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surfaceInverse,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final item = data[spot.x.toInt()];
                  final label = formatMonthLabel(item.month);
                  return LineTooltipItem(
                    '$label\n${fmtFull.format(spot.y)}/L',
                    AppTypography.body(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.brandInk,
                    ),
                  );
                }).toList();
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
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      r'R$'
                      '${fmtShort.format(value)}',
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
                  if (data.length > 6 && index % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _shortMonth(data[index].month),
                      style: AppTypography.body(10, color: AppColors.inkSoft),
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
              curveSmoothness: 0.3,
              // Cor da linha: inkMuted — dado de mercado, sem "alarmar" com cor forte
              color: AppColors.inkMuted,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3.0,
                    color: AppColors.surfaceRaised,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.inkMuted,
                  );
                },
              ),
              // Sem fill — linha pura reflete volatilidade sem peso visual extra
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      ),
    );
  }

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
