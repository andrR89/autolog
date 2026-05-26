// Card de um abastecimento na timeline da tela do veículo.
//
// Layout (editorial, hierarquia tipográfica clara):
//
//   ┌────────────────────────────────────────────────────────┐
//   │ 23 mai                                  12,4           │  eyebrow + métrica display
//   │                                          km/l           │
//   │                                                          │
//   │ 43,219 L   ·   R$ 250,00   ·   R$ 0,55/km                │  linha secundária (tabular)
//   │ Odômetro 45 312 km                                       │  odômetro discreto
//   │                                                          │  ────────────── hairline
//   │ ⛽ Tanque cheio                          manual ⌨        │  meta (tipo + origem)
//   └────────────────────────────────────────────────────────┘
//
// Decisões:
// - **Data como eyebrow PT-BR** ("23 mai") — substitui o titleMedium pesado
//   do card antigo. Mais leve, dá ar de jornal. O ano só aparece quando
//   relevante (≠ ano corrente).
// - **km/L sobe pra metric grande** (Bricolage 32/700) à direita. Mesmo
//   sem baseline, ocupa o espaço — "—" em inkSoft mantém o ritmo visual
//   entre cards consecutivos sem "buraco".
// - **Tabular figures em linha** para litros · R$ · custo/km. Manrope
//   tabular alinha colunas mesmo dentro de Wrap.
// - **Hairline interna** separa stats de meta — funciona como linha de
//   "rodapé" sem precisar de outro card aninhado.
// - **Ícones de tipo e origem** ficam pequenos e em inkMuted, presença
//   tátil mas sem competir.
//
// Interações:
// - Tap → editar entry.
// - Long press → não tem (Dismissible cuida do delete).
//
// O card é puro — não faz delete sozinho. A tela hospedeira embrulha em
// Dismissible (mesmo padrão do VehicleCard).

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/services/consumption_calculator.dart';
import 'package:autolog/features/fuel/fuel_history_helpers.dart';
import 'package:autolog/features/vehicles/widgets/fuel_type_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FuelEntryCard extends StatelessWidget {
  const FuelEntryCard({
    super.key,
    required this.row,
    required this.onTap,
    this.showYear = false,
  });

  final ConsumptionRow row;
  final VoidCallback onTap;

  /// Se true, eyebrow inclui o ano ("23 mai 2024"). Útil para entries
  /// históricas longe do ano corrente.
  final bool showYear;

  String _eyebrowDate(DateTime date) {
    // Padrão "23 mai" (ou "23 mai 2024" quando showYear).
    final pattern = showYear ? 'd MMM yyyy' : 'd MMM';
    final formatted = DateFormat(pattern, 'pt_BR').format(date);
    // intl com locale 'pt_BR' tende a devolver "Mai." — limpamos
    // pontuação e força lowercase para um eyebrow editorial.
    return formatted.replaceAll('.', '').toLowerCase();
  }

  String _odometerLabel(int km) {
    // Mesmo formato do VehicleCard — separador "fino" não-quebrável,
    // sem depender de intl pra layout consistente.
    final s = km.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write(' ');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }

  IconData _tankIcon(bool fullTank) {
    return fullTank ? Icons.local_gas_station : Icons.water_drop_outlined;
  }

  String _tankLabel(bool fullTank) {
    return fullTank ? 'Tanque cheio' : 'Parcial';
  }

  IconData _sourceIcon(FuelSource source) {
    return switch (source) {
      FuelSource.aiScan => Icons.photo_camera_outlined,
      FuelSource.ocr => Icons.center_focus_strong_outlined,
      FuelSource.manual => Icons.edit_outlined,
    };
  }

  String _sourceLabel(FuelSource source) {
    return switch (source) {
      FuelSource.aiScan => 'scan',
      FuelSource.ocr => 'ocr',
      FuelSource.manual => 'manual',
    };
  }

  @override
  Widget build(BuildContext context) {
    final entry = row.entry;
    final kmPerLiter = row.kmPerLiter;
    final costPerKm = row.costPerKm;
    final textTheme = Theme.of(context).textTheme;
    final fuel = FuelTypeStyle.of(entry.fuelType);

    final hasConsumo = kmPerLiter != null;

    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: fuel.soft,
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
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Linha 1: data eyebrow + métrica km/l ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _eyebrowDate(entry.date),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.inkMuted,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                    // Métrica à direita: número grande + unidade
                    // pequena. Mesmo quando null, ocupa espaço com "—"
                    // para manter ritmo entre cards.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasConsumo
                              ? formatKmPerLiter(
                                  kmPerLiter,
                                ).replaceAll(' km/l', '')
                              : '—',
                          style: AppTypography.metric(
                            32,
                            weight: FontWeight.w700,
                            color: hasConsumo
                                ? AppColors.ink
                                : AppColors.inkSoft,
                          ),
                        ),
                        if (hasConsumo) ...[
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              'km/l',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.inkMuted,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),

                // --- Linha 2: stats secundários (tabular) ---
                _SecondaryStats(
                  liters: formatLitersBr(entry.liters),
                  totalCost: formatCurrencyBr(entry.totalCost),
                  costPerKm: hasConsumo ? formatCostPerKm(costPerKm) : null,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Odômetro ${_odometerLabel(entry.odometer)} km',
                  style: AppTypography.tabular(
                    textTheme.bodySmall ?? const TextStyle(),
                  ).copyWith(color: AppColors.inkMuted),
                ),
                const SizedBox(height: AppSpacing.md),

                // Hairline separa stats da meta-info (tipo / fonte).
                Container(height: 1, color: AppColors.hairline),
                const SizedBox(height: AppSpacing.sm + 2),

                // --- Linha 4: tipo de tanque (esq) + origem (dir) ---
                Row(
                  children: [
                    Icon(
                      _tankIcon(entry.fullTank),
                      size: 16,
                      color: entry.fullTank
                          ? AppColors.success
                          : AppColors.inkMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      _tankLabel(entry.fullTank),
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.inkMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _sourceLabel(entry.source),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.inkSoft,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Icon(
                      _sourceIcon(entry.source),
                      size: 14,
                      color: AppColors.inkSoft,
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

class _SecondaryStats extends StatelessWidget {
  const _SecondaryStats({
    required this.liters,
    required this.totalCost,
    required this.costPerKm,
  });

  final String liters;
  final String totalCost;
  final String? costPerKm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = AppTypography.tabular(
      textTheme.bodyMedium ?? const TextStyle(),
    ).copyWith(color: AppColors.ink);

    final dividerStyle = textTheme.bodySmall?.copyWith(
      color: AppColors.inkSoft,
    );

    return DefaultTextStyle.merge(
      style: baseStyle,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(liters),
          Text('·', style: dividerStyle),
          Text(totalCost),
          if (costPerKm != null) ...[
            Text('·', style: dividerStyle),
            Text(costPerKm!),
          ],
        ],
      ),
    );
  }
}
