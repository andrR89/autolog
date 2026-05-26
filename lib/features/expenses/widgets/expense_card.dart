// Card editorial de uma despesa na timeline.
//
// Layout:
//
//   ┌────────────────────────────────────────────────────────┐
//   │ 23 mai                                  R$ 250,00       │  eyebrow + valor display
//   │ Troca de óleo                                           │  título bold (descrição)
//   │                                                          │
//   │ [● Manutenção]  ·  Odômetro 45 312 km                  │  chip categoria + odômetro
//   └────────────────────────────────────────────────────────┘
//
// Decisões:
// - Data como eyebrow PT-BR lowercase ("23 mai") — ritmo editorial.
// - Valor R$ em destaque à direita em Bricolage metric(28) — mesmo peso
//   visual de km/l no FuelEntryCard, mas alinhado à direita.
// - Descrição como título principal bold — inversão intencional: o "o quê"
//   (descrição) é mais útil que a categoria para identificação rápida.
// - Chip categoria: cor sólida por categoria (padrão FuelTypeStyle).
// - Odômetro discreto quando presente, em inkMuted.
//
// O card é puro — não faz delete. A tela embrulha em Dismissible.

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/features/expenses/widgets/expense_category_style.dart';
import 'package:autolog/features/fuel/fuel_history_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    required this.onTap,
    this.showYear = false,
  });

  final Expense expense;
  final VoidCallback onTap;

  /// Se true, eyebrow inclui o ano ("23 mai 2024"). Útil para despesas
  /// históricas de um ano diferente do corrente.
  final bool showYear;

  String _eyebrowDate(DateTime date) {
    final pattern = showYear ? 'd MMM yyyy' : 'd MMM';
    final formatted = DateFormat(pattern, 'pt_BR').format(date);
    return formatted.replaceAll('.', '').toLowerCase();
  }

  String _odometerLabel(int km) {
    final s = km.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cat = ExpenseCategoryStyle.of(expense.category);

    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: cat.soft,
        highlightColor: AppColors.surfaceSunken.withValues(alpha: 0.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.hairline, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg + 2,
              AppSpacing.md + 2,
              AppSpacing.lg + 2,
              AppSpacing.md + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Linha 1: data eyebrow (esq) + valor R$ (dir) ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _eyebrowDate(expense.date),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.inkMuted,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                    // Valor em destaque — Bricolage metric grande à direita.
                    Text(
                      formatCurrencyBr(expense.amount),
                      style: AppTypography.metric(
                        28,
                        weight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // --- Linha 2: descrição (título principal) ---
                Text(
                  expense.description,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),

                // --- Linha 3: chip categoria + odômetro opcional ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _CategoryChip(cat: cat),
                    if (expense.odometer != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 1,
                        height: 12,
                        color: AppColors.hairline,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.speed_outlined,
                        size: 13,
                        color: AppColors.inkSoft,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${_odometerLabel(expense.odometer!)} km',
                        style: AppTypography.tabular(
                          textTheme.bodySmall ?? const TextStyle(),
                        ).copyWith(color: AppColors.inkMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.cat});

  final ExpenseCategoryStyle cat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cat.soft,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cat.icon, size: 12, color: cat.color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            cat.label,
            style: textTheme.labelSmall?.copyWith(
              color: cat.color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
