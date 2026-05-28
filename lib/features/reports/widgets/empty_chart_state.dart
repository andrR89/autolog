// Estado vazio humanizado para seções de gráfico.
//
// Em vez de "Sem dados suficientes ainda", usa mensagem contextual
// que convida à ação — parte da linguagem visual "confiante, calmo, brasileiro".

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:flutter/material.dart';

class EmptyChartState extends StatelessWidget {
  const EmptyChartState({super.key, required this.message, this.height = 180});

  final String message;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone decorativo suave
              SizedBox(
                width: 36,
                height: 36,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: context.inkSoft,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  13,
                  color: context.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
