// Mapeia ExpenseCategory -> apresentação visual (cor de acento + ícone + label PT-BR).
//
// Espelha o padrão de FuelTypeStyle — centraliza a associação visual de cada
// categoria para que lista, formulário e outros widgets usem a mesma paleta.
//
// Paleta de categorias:
//   Manutenção  → success (verde) — cuidar do carro é positivo
//   Lavagem     → info (azul)     — água, limpeza
//   Estacionamento → fuelDiesel (âmbar) — neutro/urbano
//   Multa       → danger (vermelho) — negativo, chamativo
//   Seguro      → fuelFlex (roxo)  — proteção, institucional
//   IPVA        → warning (laranja) — dever fiscal, atenção
//   Outro       → inkMuted (cinza) — genérico

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:flutter/material.dart';

/// Aparência canônica de um [ExpenseCategory] para uso em UI.
class ExpenseCategoryStyle {
  const ExpenseCategoryStyle({
    required this.color,
    required this.icon,
    required this.label,
  });

  /// Cor sólida — usada em chips, ícones e faixas laterais.
  final Color color;

  /// Ícone Material representativo da categoria.
  final IconData icon;

  /// Label PT-BR capitalizado para exibição direta.
  final String label;

  /// Versão suave (18% alpha) para fundos de chip.
  Color get soft => color.withValues(alpha: 0.18);

  static ExpenseCategoryStyle of(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.manutencao:
        return const ExpenseCategoryStyle(
          color: AppColors.success,
          icon: Icons.build_outlined,
          label: 'Manutenção',
        );
      case ExpenseCategory.lavagem:
        return const ExpenseCategoryStyle(
          color: AppColors.info,
          icon: Icons.water_drop_outlined,
          label: 'Lavagem',
        );
      case ExpenseCategory.estacionamento:
        return const ExpenseCategoryStyle(
          color: AppColors.fuelDiesel,
          icon: Icons.local_parking_outlined,
          label: 'Estacionamento',
        );
      case ExpenseCategory.multa:
        return const ExpenseCategoryStyle(
          color: AppColors.danger,
          icon: Icons.gavel_outlined,
          label: 'Multa',
        );
      case ExpenseCategory.seguro:
        return const ExpenseCategoryStyle(
          color: AppColors.fuelFlex,
          icon: Icons.shield_outlined,
          label: 'Seguro',
        );
      case ExpenseCategory.ipva:
        return const ExpenseCategoryStyle(
          color: AppColors.warning,
          icon: Icons.receipt_long_outlined,
          label: 'IPVA',
        );
      case ExpenseCategory.licenciamento:
        return const ExpenseCategoryStyle(
          color: AppColors.warning,
          icon: Icons.assignment_outlined,
          label: 'Licenciamento',
        );
      case ExpenseCategory.outro:
        return const ExpenseCategoryStyle(
          color: AppColors.inkMuted,
          icon: Icons.more_horiz,
          label: 'Outro',
        );
    }
  }
}
