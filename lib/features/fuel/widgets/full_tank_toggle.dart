// Toggle "Enchi o tanque até o final" — substitui o SwitchListTile cru.
//
// Por que matérial em vez do SwitchListTile padrão: o estado "tanque cheio"
// é semanticamente importante (faz o cálculo de consumo entrar em ação).
// Merecia mais que uma linha de lista anônima. Aqui mostra:
//
//   - quando ATIVO: card sutil em successSoft + ícone bomba verde, copy
//     "Enchi o tanque até o final", subcopy "Esse abastecimento entra no
//     cálculo de km/L".
//   - quando INATIVO: card surfaceSunken + ícone gota outlined, copy
//     "Abastecimento parcial", subcopy "Não entra no cálculo de média".
//
// O switch real fica à direita (theme = brand verde quando ligado).

import 'package:autolog/core/design/tokens.dart';
import 'package:flutter/material.dart';

class FullTankToggle extends StatelessWidget {
  const FullTankToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bgColor = value
        ? AppColors.successSoft
        : AppColors.surfaceSunken.withValues(alpha: 0.65);
    final iconColor = value ? AppColors.success : AppColors.inkMuted;
    final icon = value
        ? Icons.local_gas_station_rounded
        : Icons.water_drop_outlined;
    final title = value
        ? 'Enchi o tanque até o final'
        : 'Abastecimento parcial';
    final subtitle = value
        ? 'Entra no cálculo de km/L do próximo cheio.'
        : 'Não conta como baseline para a média de consumo.';

    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.standardCurve,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: value
              ? AppColors.success.withValues(alpha: 0.18)
              : AppColors.hairline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          splashColor: value
              ? AppColors.success.withValues(alpha: 0.08)
              : AppColors.hairline,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md + 2,
              AppSpacing.sm,
              AppSpacing.md + 2,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.standard,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: value
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
