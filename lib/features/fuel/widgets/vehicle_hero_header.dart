// Cabeçalho hero da tela do veículo — a "capa" do dashboard.
//
// Anatomia:
//
//   ┌────────────────────────────────────────────────────────┐
//   │  ▓ Painel verde-meia-noite (brand)                       │
//   │                                                          │
//   │    Civic                                  ● Flex         │   nickname + fuel chip
//   │    Honda Civic · 2018  [ ABC1D23 ]                       │   sub + plate
//   │                                                          │
//   │    ÚLTIMO CONSUMO                                        │   eyebrow
//   │    12,4  km/l                                            │   hero metric
//   │                                                          │
//   └────────────────────────────────────────────────────────┘
//   ┌────────────────────────────────────────────────────────┐
//   │  Faixa de stats do mês — fundo surface, hairline top      │
//   │  MAIO/2026                                                │
//   │  R$ 432,10 gastos   ·   3 abastecimentos                  │
//   └────────────────────────────────────────────────────────┘
//
// Por quê tom escuro no painel hero: o resto da tela é off-white quente
// (cards, lista). O contraste do brand dá "peso" ao topo sem precisar de
// sombra; faz a métrica grande respirar como um marcador de dashboard de
// carro à noite. Lima nunca entra aqui — fica reservada pro FAB.
//
// Sem baseline (carro novo, primeiro abastecimento ainda): mostra "—"
// + tagline convidativa. Não dá erro, não some — é parte do convite.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_history_helpers.dart';
import 'package:autolog/features/vehicles/widgets/fuel_type_style.dart';
import 'package:autolog/features/vehicles/widgets/plate_strip.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleHeroHeader extends StatelessWidget {
  const VehicleHeroHeader({
    super.key,
    required this.vehicle,
    required this.heroKmPerLiter,
    required this.heroLabel,
    required this.monthSpend,
    required this.monthCount,
    required this.monthLabel,
  });

  final Vehicle vehicle;

  /// Métrica em destaque (km/L). Null = ainda sem baseline.
  final Decimal? heroKmPerLiter;

  /// Label da métrica — varia conforme contexto ("Último consumo", "Média
  /// recente", "Aguardando baseline").
  final String heroLabel;

  /// Total gasto no mês corrente. Decimal.zero quando vazio.
  final Decimal monthSpend;

  /// Quantidade de abastecimentos no mês corrente.
  final int monthCount;

  /// Label do mês no formato "MAIO/2026" (já uppercase).
  final String monthLabel;

  String? _buildSubtitle() {
    final parts = <String>[
      if (vehicle.make != null && vehicle.make!.trim().isNotEmpty)
        vehicle.make!.trim(),
      if (vehicle.model != null && vehicle.model!.trim().isNotEmpty)
        vehicle.model!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _buildSubtitle();
    final fuel = FuelTypeStyle.of(vehicle.fuelType);
    final textTheme = Theme.of(context).textTheme;
    final hasBaseline = heroKmPerLiter != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Painel hero (brand) ---
        Container(
          decoration: const BoxDecoration(color: AppColors.brand),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha 1: nickname + fuel chip (variante escura).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      vehicle.nickname,
                      style: AppTypography.display(
                        34,
                        weight: FontWeight.w700,
                        height: 1.05,
                        color: AppColors.brandInk,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _DarkFuelChip(fuel: fuel),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.brandInk.withValues(alpha: 0.62),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              // Linha 2: plate strip pequeno.
              Align(
                alignment: Alignment.centerLeft,
                child: PlateStrip(plate: vehicle.plate),
              ),
              const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

              // Eyebrow + hero metric.
              Text(
                heroLabel.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.brandInk.withValues(alpha: 0.55),
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _HeroMetric(kmPerLiter: heroKmPerLiter),
              if (!hasBaseline) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Registre dois cheios e a média aparece aqui.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.brandInk.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),

        // --- Faixa de stats do mês (sob o painel hero) ---
        _MonthStrip(
          monthLabel: monthLabel,
          spend: monthSpend,
          count: monthCount,
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.kmPerLiter});

  final Decimal? kmPerLiter;

  @override
  Widget build(BuildContext context) {
    final hasValue = kmPerLiter != null;
    final formatted = hasValue
        ? formatKmPerLiter(kmPerLiter).replaceAll(' km/l', '')
        : '—';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            formatted,
            style: AppTypography.metric(
              64,
              weight: FontWeight.w700,
              color: hasValue
                  ? AppColors.brandInk
                  : AppColors.brandInk.withValues(alpha: 0.45),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasValue) ...[
          const SizedBox(width: AppSpacing.sm + 2),
          Padding(
            // Alinha o "km/l" com a baseline visual dos numerais grandes
            // (Bricolage tem ascender alto; descer 14px alinha "k" e "1").
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              'km/l',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 1.0,
                color: AppColors.brandInk.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Chip de combustível otimizado para fundo escuro (brand).
///
/// FuelChip default usa style.soft (12% sobre branco) — invisível sobre
/// brand. Aqui usamos um alpha maior e texto brandInk.
class _DarkFuelChip extends StatelessWidget {
  const _DarkFuelChip({required this.fuel});

  final FuelTypeStyle fuel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        // Fundo escuro mais saturado da cor do combustível (alpha 22%)
        // pra "queimar" sobre o brand sem virar pastel.
        color: fuel.color.withValues(alpha: 0.22),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: fuel.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            fuel.label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.brandInk,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthStrip extends StatelessWidget {
  const _MonthStrip({
    required this.monthLabel,
    required this.spend,
    required this.count,
  });

  final String monthLabel;
  final Decimal spend;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasAny = count > 0;
    final spendText = hasAny ? formatCurrencyBr(spend) : r'R$ 0,00';
    final countText = switch (count) {
      0 => 'nenhum abastecimento',
      1 => '1 abastecimento',
      _ => '$count abastecimentos',
    };

    return Container(
      width: double.infinity,
      color: context.surface,
      // Container full-width (faixa visual sob o hero brand-dark) mas o
      // conteúdo dentro centraliza em ResponsiveWidths.content pra
      // alinhar com os cards de detalhe (C1.5).
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: context.inkMuted,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      spendText,
                      style: AppTypography.metric(22, weight: FontWeight.w600),
                    ),
                    const SizedBox(width: AppSpacing.sm + 2),
                    // "vírgula respiratória" em hairline pra dar ritmo editorial
                    // sem precisar de bullet visual.
                    Container(width: 1, height: 14, color: context.hairline),
                    const SizedBox(width: AppSpacing.sm + 2),
                    Flexible(
                      child: Text(
                        countText,
                        style: textTheme.bodyMedium?.copyWith(
                          color: context.inkMuted,
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
      ),
    );
  }
}
