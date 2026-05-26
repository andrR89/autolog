import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/features/reports/trend_analyzer.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// Badge de tendência reutilizável.
///
/// [direction]: direção da tendência.
/// [deltaPercent]: variação percentual (positiva = subiu, negativa = caiu).
/// [goodWhenDown]: true → queda é boa (ex: gasto); false → queda é ruim
/// (ex: consumo km/L).
class TrendBadge extends StatelessWidget {
  const TrendBadge({
    super.key,
    required this.direction,
    required this.deltaPercent,
    this.goodWhenDown = true,
  });

  final TrendDirection direction;
  final Decimal deltaPercent;
  final bool goodWhenDown;

  @override
  Widget build(BuildContext context) {
    final isStable = direction == TrendDirection.stable;

    // Determina se a mudança é "boa" para o usuário.
    final bool isGood;
    if (isStable) {
      isGood = true; // estável = neutro, exibimos em cinza
    } else if (goodWhenDown) {
      isGood = direction == TrendDirection.down;
    } else {
      isGood = direction == TrendDirection.up;
    }

    final Color fgColor;
    final Color bgColor;
    if (isStable) {
      fgColor = AppColors.inkMuted;
      bgColor = AppColors.surfaceSunken;
    } else if (isGood) {
      fgColor = AppColors.success;
      bgColor = AppColors.successSoft;
    } else {
      fgColor = AppColors.danger;
      bgColor = AppColors.dangerSoft;
    }

    final IconData icon = switch (direction) {
      TrendDirection.up => Icons.trending_up,
      TrendDirection.down => Icons.trending_down,
      TrendDirection.stable => Icons.trending_flat,
    };

    final absValue = deltaPercent.abs();
    final sign = deltaPercent > Decimal.zero
        ? '+'
        : deltaPercent < Decimal.zero
            ? ''
            : '';
    // Format: ±X,X%
    final formatted =
        '$sign${absValue.toDouble().toStringAsFixed(1).replaceAll('.', ',')}%';
    final label = deltaPercent < Decimal.zero
        ? '-${absValue.toDouble().toStringAsFixed(1).replaceAll('.', ',')}%'
        : formatted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
