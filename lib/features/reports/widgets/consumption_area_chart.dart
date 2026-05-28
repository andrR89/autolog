// Gráfico de área para consumo médio (km/l) por mês.
//
// Design:
// - Linha suave (isCurved: true) em cor brand.
// - Fill com gradient de accent/lima → transparent, evocando "eficiência verde".
// - Pontos discretos com borda brand. Marcador do último ponto em destaque.
// - Grid horizontal hairline. Sem borda externa.
// - Tooltip com valor formatado em km/L.
// - ANIMAÇÃO: swapAnimationDuration 800ms easeOutCubic.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/features/reports/monthly_consumption.dart';
import 'package:autolog/features/reports/reports_helpers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConsumptionAreaChart extends StatelessWidget {
  const ConsumptionAreaChart({super.key, required this.data});

  final List<MonthlyConsumption> data;

  @override
  Widget build(BuildContext context) {
    // Conversão Decimal→double APENAS na borda de display (FlSpot).
    final spots = [
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].kmPerLiter.toDouble()),
    ];

    final allValues = spots.map((s) => s.y).toList();
    final minY = allValues.isEmpty
        ? 0.0
        : allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.isEmpty
        ? 20.0
        : allValues.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) < 1.0 ? 2.0 : (maxY - minY) * 0.25;
    final chartMinY = (minY - padding).clamp(0.0, double.infinity);
    final chartMaxY = maxY + padding;

    final fmt = NumberFormat('0.0', 'pt_BR');

    // Capture dynamic colors before fl_chart callbacks (no BuildContext inside).
    final hairline = context.hairline;
    final inkSoft = context.inkSoft;
    final surfaceRaised = context.surfaceRaised;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: hairline,
              strokeWidth: 1,
              dashArray: [4, 4],
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
                    '$label\n${fmt.format(spot.y)} km/L',
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
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      fmt.format(value),
                      style: AppTypography.body(10, color: inkSoft),
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
                      style: AppTypography.body(10, color: inkSoft),
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
              curveSmoothness: 0.35,
              color: AppColors.brand,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isLast = index == spots.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 5.0 : 3.5,
                    color: isLast ? AppColors.brand : surfaceRaised,
                    strokeWidth: isLast ? 0 : 2,
                    strokeColor: AppColors.brand,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // Accent lima-cítrica → transparent: evoca "área verde de eficiência"
                    AppColors.accent.withValues(alpha: 0.28),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
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
