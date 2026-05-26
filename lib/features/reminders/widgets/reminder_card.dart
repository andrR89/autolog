// Card editorial de um lembrete na lista de tarefas.
//
// Layout:
//
//   ┌────────────────────────────────────────────────────────┐
//   │ ○  Troca de óleo                         [porKm]        │  checkbox · título · chip tipo
//   │    ⚡ Por km · Alvo: 50.000 km                          │  sub: alvo + ícone contextual
//   └────────────────────────────────────────────────────────┘
//
// Quando isDone:
//   ┌────────────────────────────────────────────────────────┐
//   │ ✓  ~~Troca de óleo~~                     [porKm]        │  strikethrough + inkMuted
//   │    ⚡ Por km · Alvo: 50.000 km                          │
//   └────────────────────────────────────────────────────────┘
//
// Decisões:
// - Leading: Checkbox com toggleDone — mesma lógica da versão antiga.
// - Título bold; quando done, strikethrough + cor inkMuted.
// - Chip de tipo discreto à direita (porKm azul / porData laranja).
// - Sub com ícone contextual: speedometer (porKm) / calendar (porData).
// - Quando porData e vencimento próximo (≤7 dias), exibe badge warning.
//
// O card é puro — não faz delete. A tela embrulha em Dismissible.

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/features/fuel/fuel_history_helpers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formata [km] com separador de milhar PT-BR.
String _formatKm(int km) => NumberFormat('#,##0', 'pt_BR').format(km);

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onToggleDone,
  });

  final Reminder reminder;
  final VoidCallback onTap;
  final VoidCallback onToggleDone;

  /// Quantos dias até o vencimento (negativo = vencido).
  int? _daysUntilDue() {
    if (reminder.type != ReminderType.porData || reminder.dueDate == null) {
      return null;
    }
    final now = DateTime.now();
    return reminder.dueDate!
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  String _dueLabel() {
    if (reminder.type == ReminderType.porKm && reminder.dueKm != null) {
      return 'Alvo: ${_formatKm(reminder.dueKm!)} km';
    }
    if (reminder.type == ReminderType.porData && reminder.dueDate != null) {
      final days = _daysUntilDue()!;
      final dateStr = formatDateBr(reminder.dueDate!);
      if (days < 0) return 'Alvo: $dateStr · vencido';
      if (days == 0) return 'Alvo: $dateStr · hoje';
      if (days <= 7) return 'Alvo: $dateStr · em $days dias';
      return 'Alvo: $dateStr';
    }
    return '';
  }

  bool get _isUrgent {
    final days = _daysUntilDue();
    return days != null && days <= 7 && !reminder.isDone;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDone = reminder.isDone;
    final urgent = _isUrgent;

    // Cor de borda: urgente = warning, normal = hairline.
    final borderColor = urgent ? AppColors.warning : AppColors.hairline;

    return Material(
      color: isDone
          ? AppColors.surfaceSunken.withValues(alpha: 0.6)
          : AppColors.surfaceRaised,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brand.withValues(alpha: 0.06),
        highlightColor: AppColors.surfaceSunken.withValues(alpha: 0.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox leading.
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Checkbox(
                      value: isDone,
                      onChanged: (_) => onToggleDone(),
                      activeColor: AppColors.success,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Conteúdo.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs + 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Linha 1: título + chip tipo.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                style: textTheme.titleMedium?.copyWith(
                                  color: isDone
                                      ? AppColors.inkMuted
                                      : AppColors.ink,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: AppColors.inkMuted,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _TypeChip(type: reminder.type),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Linha 2: sub com ícone contextual.
                        Row(
                          children: [
                            Icon(
                              reminder.type == ReminderType.porKm
                                  ? Icons.speed_outlined
                                  : Icons.calendar_today_outlined,
                              size: 13,
                              color: urgent
                                  ? AppColors.warning
                                  : AppColors.inkSoft,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                _dueLabel(),
                                style: textTheme.bodySmall?.copyWith(
                                  color: urgent
                                      ? AppColors.warning
                                      : AppColors.inkMuted,
                                  fontWeight: urgent
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip discreto do tipo de lembrete.
///
/// porKm → azul info · porData → laranja warning.
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final ReminderType type;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final color = switch (type) {
      ReminderType.porKm => AppColors.info,
      ReminderType.porData => AppColors.warning,
    };
    final label = switch (type) {
      ReminderType.porKm => 'por km',
      ReminderType.porData => 'por data',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(color: color, letterSpacing: 0.3),
      ),
    );
  }
}
