// Empty state da lista de lembretes.
//
// Convidativo, explica o valor antes de pedir a ação.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/dashed_frame.dart';
import 'package:flutter/material.dart';

class RemindersEmptyState extends StatelessWidget {
  const RemindersEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DashedFrame(icon: Icons.notifications_none_outlined),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Nenhum lembrete cadastrado.',
                style: AppTypography.display(
                  26,
                  weight: FontWeight.w700,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Toque em "Novo lembrete" pra não esquecer manutenções, '
                'seguros e datas importantes do seu carro.',
                style: textTheme.bodyMedium?.copyWith(
                  color: context.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),
              // CTA único: FAB "Novo lembrete" do Scaffold.
            ],
          ),
        ),
      ),
    );
  }
}
