// Empty state da garagem. Primeiro toque no app pra quem acabou de
// criar conta: tem que ser CONVIDATIVO, não "você não tem nada".
//
// Composição:
// - "Vaga de garagem": frame off-white com hairline tracejado.
// - Ícone de carro centralizado, peso leve.
// - Headline calorosa + subhead com instrução prática.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/dashed_frame.dart';
import 'package:flutter/material.dart';

class VehiclesEmptyState extends StatelessWidget {
  const VehiclesEmptyState({super.key});

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
              // Frame um pouco maior + ícone mais nítido — é o "hero" da
              // tela de boas-vindas pós-cadastro.
              const DashedFrame(
                icon: Icons.directions_car_filled_outlined,
                height: 140,
                iconSize: 64,
                iconAlpha: 0.35,
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Sua garagem está esperando.',
                style: AppTypography.display(
                  26,
                  weight: FontWeight.w700,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Adicione seu primeiro carro pra começar a registrar '
                'abastecimentos, despesas e lembretes.',
                style: textTheme.bodyMedium?.copyWith(
                  color: context.inkMuted,
                ),
                textAlign: TextAlign.center,
              ),
              // CTA único: FloatingActionButton "Novo veículo" no Scaffold.
            ],
          ),
        ),
      ),
    );
  }
}
