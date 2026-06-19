// Cabeçalho hero da tela de lembretes.
//
// Anatomia:
//
//   ┌────────────────────────────────────────────────────────┐
//   │  ▓ Painel verde-meia-noite (brand)                       │
//   │                                                          │
//   │    Civic                        [ ABC1D23 ]              │  nickname + plate
//   │                                                          │
//   │    LEMBRETES                                             │  eyebrow
//   │    3 pendentes                                           │  hero counter
//   │  — ou —                                                  │
//   │    Tudo em dia ✓                                         │  hero (quando tudo done)
//   │                                                          │
//   └────────────────────────────────────────────────────────┘
//
// Mood diferente do hero de despesas: transmite "lista de tarefas" com
// contador de pendências em destaque. Quando tudo está done, exibe
// celebração discreta ("Tudo em dia") em accent (única exceção de uso
// do lima num hero).

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:flutter/material.dart';

class RemindersHeroHeader extends StatelessWidget {
  const RemindersHeroHeader({
    super.key,
    required this.vehicle,
    required this.pendingCount,
    required this.totalCount,
  });

  final Vehicle vehicle;

  /// Quantidade de lembretes pendentes (isDone == false).
  final int pendingCount;

  /// Total de lembretes (incluindo feitos).
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final allDone = totalCount > 0 && pendingCount == 0;
    final empty = totalCount == 0;

    // Slot do topo em fonte display 44 — frases longas truncam com elipse
    // ("Nenhum lembr…"). Mantemos um STAT curto e numérico quando vazio,
    // alinhando com o padrão de Despesas ("R$ 0,00") (UX 19/06 — m2).
    final heroText = switch ((allDone, empty)) {
      (true, _) => 'Tudo em dia',
      (_, true) => '0 pendentes',
      _ => switch (pendingCount) {
        1 => '1 pendente',
        _ => '$pendingCount pendentes',
      },
    };

    final heroColor = allDone
        ? AppColors
              .accent // lima celebração
        : empty
        ? AppColors.brandInk.withValues(alpha: 0.45)
        : AppColors.brandInk;

    // Top padding interno cobre status bar + AppBar transparente, evitando
    // que o off-white do Scaffold vaze sobre o brand-dark.
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Container(
      decoration: const BoxDecoration(color: AppColors.brand),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        topInset + AppSpacing.md,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: nickname + plate.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  vehicle.nickname,
                  style: AppTypography.display(
                    28,
                    weight: FontWeight.w700,
                    height: 1.1,
                    color: AppColors.brandInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _DarkPlateStrip(plate: vehicle.plate),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

          // Eyebrow.
          Text(
            'LEMBRETES',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.brandInk.withValues(alpha: 0.55),
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Hero counter.
          Text(
            heroText,
            style: AppTypography.metric(
              44,
              weight: FontWeight.w700,
              color: heroColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Sub: total quando há pendentes.
          if (!allDone && !empty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              switch (totalCount) {
                1 => '1 lembrete no total',
                _ => '$totalCount lembretes no total',
              },
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ],

          // Mensagem celebração quando tudo done.
          if (allDone) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Todos os lembretes foram concluídos.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.brandInk.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DarkPlateStrip extends StatelessWidget {
  const _DarkPlateStrip({required this.plate});

  final String? plate;

  @override
  Widget build(BuildContext context) {
    final hasPlate = plate != null && plate!.trim().isNotEmpty;
    final display = hasPlate ? plate!.trim().toUpperCase() : 'sem placa';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandInk.withValues(alpha: 0.12),
        borderRadius: AppRadius.allSm,
        border: Border.all(
          color: AppColors.brandInk.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        display,
        style:
            AppTypography.display(
              13,
              weight: hasPlate ? FontWeight.w700 : FontWeight.w500,
              color: hasPlate
                  ? AppColors.brandInk
                  : AppColors.brandInk.withValues(alpha: 0.45),
            ).copyWith(
              letterSpacing: hasPlate ? 1.4 : 0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontStyle: hasPlate ? FontStyle.normal : FontStyle.italic,
            ),
      ),
    );
  }
}
