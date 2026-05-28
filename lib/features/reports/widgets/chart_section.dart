// Seção editorial de gráfico — substitui o Card genérico.
//
// Anatomia:
//
//   ┌───────────────────────────────────────────────────────────┐
//   │  OVERLINE LABEL                                           │
//   │  Título da seção                      [insight callout]   │
//   │                                                           │
//   │  [gráfico animado]                                        │
//   └───────────────────────────────────────────────────────────┘
//
// Não usa Card (que adicionaria borda uniform). Usa separação visual por
// espaçamento e overline colorida — estilo editorial, não formulário.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:flutter/material.dart';

class ChartSection extends StatelessWidget {
  const ChartSection({
    super.key,
    required this.overline,
    required this.title,
    required this.chart,
    this.insight,
    this.overlineColor,
  });

  /// Label acima do título — ex: "GASTO", "CONSUMO", "PREÇO/LITRO"
  final String overline;

  /// Título principal — ex: "Por mês"
  final String title;

  /// Conteúdo do gráfico (já dimensionado com altura fixa).
  final Widget chart;

  /// Texto opcional de insight contextual — ex: "Média do mês: 12,5 km/L"
  final String? insight;

  /// Cor do overline — diferencia visualmente cada seção.
  final Color? overlineColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.surfaceRaised,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overline
            Text(
              overline.toUpperCase(),
              style: AppTypography.body(
                10,
                weight: FontWeight.w700,
                letterSpacing: 1.8,
                color: overlineColor ?? AppColors.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),

            // Título + insight inline
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  title,
                  style: AppTypography.display(
                    20,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                if (insight != null) ...[
                  const Spacer(),
                  Flexible(
                    child: Text(
                      insight!,
                      textAlign: TextAlign.end,
                      style: AppTypography.body(12, color: context.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Gráfico
            chart,
          ],
        ),
      ),
    );
  }
}
