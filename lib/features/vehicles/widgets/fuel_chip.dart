// Chip compacto com bolinha colorida + label PT-BR do combustível.
//
// Substitui o uso de Chip default do Material (que vem com padding pesado
// e ripple gritante). É só um Container — papel, não componente.

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/vehicles/widgets/fuel_type_style.dart';
import 'package:flutter/material.dart';

class FuelChip extends StatelessWidget {
  const FuelChip({super.key, required this.fuelType});

  final FuelType fuelType;

  @override
  Widget build(BuildContext context) {
    final style = FuelTypeStyle.of(fuelType);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: style.soft,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bolinha sólida — única "voz da cor" do combustível dentro
          // do chip; mantém o chip legível mesmo com soft de baixa
          // saturação no fundo.
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            style.label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.ink,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
