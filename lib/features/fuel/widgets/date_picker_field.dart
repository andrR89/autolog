// Campo de data como "tile elegante" — substitui o InputDecorator hack-y
// que o form antigo usava (InkWell engolindo um InputDecorator com Text
// dentro, sem semântica de campo).
//
// Layout horizontal: ícone calendário pequeno à esquerda, label uppercase
// + data formatada em pt-BR, chevron à direita pra sinalizar "abre seletor".

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({super.key, required this.value, required this.onTap});

  final DateTime value;
  final VoidCallback onTap;

  String _formatPtBr(DateTime d) {
    const meses = [
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
    final dd = d.day.toString().padLeft(2, '0');
    final mmm = meses[d.month - 1];
    return '$dd de $mmm de ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: context.surfaceSunken,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: context.hairline,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md + 2,
            AppSpacing.md,
            AppSpacing.md + 2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 18,
                color: context.inkMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'DATA',
                      style: textTheme.labelSmall?.copyWith(
                        color: context.inkSoft,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatPtBr(value),
                      style: AppTypography.body(
                        15,
                        weight: FontWeight.w600,
                        color: context.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: context.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
