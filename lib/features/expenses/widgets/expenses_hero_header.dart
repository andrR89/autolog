// Cabeçalho hero da tela de despesas — espelha VehicleHeroHeader.
//
// Anatomia:
//
//   ┌────────────────────────────────────────────────────────┐
//   │  ▓ Painel verde-meia-noite (brand)                       │
//   │                                                          │
//   │    Civic                        [ ABC1D23 ]              │  nickname + plate
//   │                                                          │
//   │    GASTO ESTE MÊS                                        │  eyebrow
//   │    R$ 432,10                                             │  hero metric
//   │    Últimos 30 dias · 3 despesas                          │  sub-info discreta
//   │                                                          │
//   └────────────────────────────────────────────────────────┘
//
// O painel hero usa brand escuro para dar "peso" ao topo — mesmo princípio
// do VehicleHeroHeader. O valor total em Bricolage metric grande dá a
// sensação de "dashboard financeiro pessoal do carro".

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_history_helpers.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

class ExpensesHeroHeader extends StatelessWidget {
  const ExpensesHeroHeader({
    super.key,
    required this.vehicle,
    required this.totalLast30Days,
    required this.countLast30Days,
  });

  final Vehicle vehicle;

  /// Soma das despesas dos últimos 30 dias. Decimal.zero quando vazio.
  final Decimal totalLast30Days;

  /// Quantidade de despesas nos últimos 30 dias.
  final int countLast30Days;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasExpenses = countLast30Days > 0;

    final countText = switch (countLast30Days) {
      0 => 'nenhuma despesa',
      1 => '1 despesa',
      _ => '$countLast30Days despesas',
    };

    // Top padding interno cobre a área da status bar + AppBar transparente
    // (extendBodyBehindAppBar: true no scaffold). Assim o brand-dark sobe até
    // o topo da tela sem o off-white do Scaffold vazar.
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
              // PlateStrip adaptado para fundo escuro.
              _DarkPlateStrip(plate: vehicle.plate),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

          // Eyebrow.
          Text(
            'GASTO ESTE MÊS',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.brandInk.withValues(alpha: 0.55),
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Hero metric — valor total.
          Text(
            hasExpenses ? formatCurrencyBr(totalLast30Days) : r'R$ 0,00',
            style: AppTypography.metric(
              52,
              weight: FontWeight.w700,
              color: hasExpenses
                  ? AppColors.brandInk
                  : AppColors.brandInk.withValues(alpha: 0.45),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Sub: "Últimos 30 dias · N despesas".
          Row(
            children: [
              Text(
                'Últimos 30 dias',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.brandInk.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 1,
                height: 12,
                color: AppColors.brandInk.withValues(alpha: 0.25),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                countText,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.brandInk.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Variante da PlateStrip otimizada para fundo escuro (brand).
///
/// A PlateStrip default usa AppColors.surface (off-white) de fundo —
/// invisível sobre o painel brand. Aqui usamos um fundo semi-transparente
/// mais escuro/leve para destacar no brand.
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
