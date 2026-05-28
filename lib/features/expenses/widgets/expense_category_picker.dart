// Seletor de categoria de despesa em pílulas horizontais — análogo ao
// FuelTypeSegmented do formulário de abastecimento.
//
// Por que pílulas em vez de DropdownButtonFormField: dropdown esconde as
// opções, força um tap a mais e é menos expressivo visualmente. Aqui o
// usuário vê todas as categorias de uma vez em scroll horizontal,
// com ícone + label, e muda com um tap.
//
// Cada pílula em estado inativo usa surfaceSunken + inkMuted.
// A selecionada ganha fundo brand.withValues(alpha: 0.1), borda brand e
// texto brand em peso 700 — padrão de "seleção suave" do DS.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:flutter/material.dart';

/// Ícone e label PT-BR de cada categoria.
class _CatMeta {
  const _CatMeta(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _meta = <ExpenseCategory, _CatMeta>{
  ExpenseCategory.manutencao: _CatMeta(Icons.build_outlined, 'Manutenção'),
  ExpenseCategory.lavagem: _CatMeta(Icons.water_drop_outlined, 'Lavagem'),
  ExpenseCategory.estacionamento: _CatMeta(
    Icons.local_parking_outlined,
    'Estacionamento',
  ),
  ExpenseCategory.multa: _CatMeta(Icons.gavel_outlined, 'Multa'),
  ExpenseCategory.seguro: _CatMeta(Icons.shield_outlined, 'Seguro'),
  ExpenseCategory.ipva: _CatMeta(Icons.receipt_long_outlined, 'IPVA'),
  ExpenseCategory.licenciamento: _CatMeta(Icons.assignment_outlined, 'Licenciamento'),
  ExpenseCategory.outro: _CatMeta(Icons.more_horiz, 'Outro'),
};

class ExpenseCategoryPicker extends StatelessWidget {
  const ExpenseCategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ExpenseCategory value;
  final ValueChanged<ExpenseCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: ExpenseCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final cat = ExpenseCategory.values[i];
          final m = _meta[cat]!;
          final selected = cat == value;
          return _CategoryChip(
            icon: m.icon,
            label: m.label,
            selected: selected,
            onTap: () => onChanged(cat),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const selectedColor = AppColors.brand;

    return Material(
      color: selected
          ? selectedColor.withValues(alpha: 0.10)
          : context.surfaceSunken,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: selectedColor.withValues(alpha: 0.10),
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
              color: selected ? selectedColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? selectedColor : context.inkMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: selected ? selectedColor : context.inkMuted,
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
