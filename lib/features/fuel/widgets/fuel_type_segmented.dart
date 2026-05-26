// Seletor de tipo de combustível em "tiras" horizontais (em vez de
// DropdownButtonFormField default).
//
// Por quê: dropdown esconde as opções num menu — força um tap a mais e
// quebra o ritmo visual do formulário. Aqui mostramos as 5 opções de uma
// vez como pílulas roláveis horizontais, com a cor canônica de cada
// combustível (FuelTypeStyle). O usuário troca com um tap.
//
// O selecionado ganha "fundo da cor" (saturado leve, alpha 18%), borda
// hairline -> cor do combustível, e label em peso 700. Não-selecionados
// ficam em surfaceSunken neutro com label inkMuted — eles existem como
// opção, mas não chamam atenção.

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/features/vehicles/widgets/fuel_type_style.dart';
import 'package:flutter/material.dart';

class FuelTypeSegmented extends StatelessWidget {
  const FuelTypeSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowed,
  });

  final FuelType value;
  final ValueChanged<FuelType> onChanged;

  /// Lista de tipos a exibir. Quando null, exibe todos os 5 tipos (legado).
  /// Quando informada, exibe apenas os tipos da lista (contextual ao veículo).
  final List<FuelType>? allowed;

  static const _allTypes = <FuelType>[
    FuelType.gasolina,
    FuelType.etanol,
    FuelType.diesel,
    FuelType.flex,
    FuelType.gnv,
  ];

  @override
  Widget build(BuildContext context) {
    final types = allowed ?? _allTypes;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: types.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final t = types[i];
          final style = FuelTypeStyle.of(t);
          final selected = t == value;
          return _FuelTypeChip(
            label: style.label,
            color: style.color,
            selected: selected,
            onTap: () => onChanged(t),
          );
        },
      ),
    );
  }
}

class _FuelTypeChip extends StatelessWidget {
  const _FuelTypeChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? color.withValues(alpha: 0.14) : AppColors.surfaceSunken,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(AppRadius.pill),
            ),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: selected ? AppColors.ink : AppColors.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
