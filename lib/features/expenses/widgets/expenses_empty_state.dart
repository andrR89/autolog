// Empty state da lista de despesas.
//
// Convidativo, não vazio — mesmo tom de VehiclesEmptyState.
// Usa um frame tracejado com ícone de recibo, headline calorosa e CTA inline.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/dashed_frame.dart';
import 'package:flutter/material.dart';

class ExpensesEmptyState extends StatelessWidget {
  const ExpensesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Scroll + Center: fica centralizado quando cabe; scrollável quando o
    // conteúdo é maior que o viewport (telas curtas, banner empurrando, etc).
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DashedFrame(icon: Icons.receipt_long_outlined),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Sem despesas registradas ainda.',
                  style: AppTypography.display(
                    26,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Toque em "Nova despesa" pra começar a controlar os gastos do seu carro.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                // CTA único: FAB "Nova despesa" do Scaffold.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

