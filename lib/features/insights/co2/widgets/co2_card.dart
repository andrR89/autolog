// Card de emissão de CO₂ — Sprint 6.CC.
//
// Exibe a pegada de carbono do veículo com toggle mês/ano, gCO₂/km
// e equivalência em árvores.
//
// Layout:
//   ┌─────────────────────────────────────────────────────┐
//   │  🌿  EMISSÃO DE CO₂              [Mês]  [Ano]       │
//   │                                                       │
//   │  88,40 kg CO₂                                        │
//   │  gCO₂/km: 177                                        │
//   │                                                       │
//   │  Para compensar, ~4 árvores por ano                  │
//   │  Considera apenas a queima do combustível            │
//   └─────────────────────────────────────────────────────┘
//
// Segue os mesmos tokens de design dos outros cards (tokens.dart, dynamic_colors.dart).
// Dark-aware via context.* extensions de DynamicColors.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/insights/co2/co2_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Co2InsightCard — public entry point
// ---------------------------------------------------------------------------

/// Card de emissão de CO₂ para o detalhe do veículo.
///
/// Exibe o total mensal (padrão) ou anual com toggle.
/// Omitido silenciosamente enquanto carrega ou em caso de erro.
class Co2InsightCard extends ConsumerStatefulWidget {
  const Co2InsightCard({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<Co2InsightCard> createState() => _Co2InsightCardState();
}

enum _Period { month, year }

class _Co2InsightCardState extends ConsumerState<Co2InsightCard> {
  _Period _period = _Period.month;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Escolhe o provider conforme o toggle selecionado.
    final resultAsync = switch (_period) {
      _Period.month => ref.watch(
        co2ForMonthProvider(
          Co2MonthArgs(
            vehicleId: widget.vehicle.id,
            year: now.year,
            month: now.month,
            vehicleInitialOdometer: widget.vehicle.initialOdometer,
          ),
        ),
      ),
      _Period.year => ref.watch(
        co2ForYearProvider(
          Co2YearArgs(
            vehicleId: widget.vehicle.id,
            vehicleInitialOdometer: widget.vehicle.initialOdometer,
          ),
        ),
      ),
    };

    return resultAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (result) {
        // Omite o card se não houver abastecimentos no período.
        if (result.entriesCount == 0) return const SizedBox.shrink();

        return _Co2CardContent(
          result: result,
          period: _period,
          onPeriodChanged: (p) => setState(() => _period = p),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _Co2CardContent — conteúdo interno
// ---------------------------------------------------------------------------

class _Co2CardContent extends StatelessWidget {
  const _Co2CardContent({
    required this.result,
    required this.period,
    required this.onPeriodChanged,
  });

  final dynamic result; // Co2Result — evita import circular no teste
  final _Period period;
  final void Function(_Period) onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_dynamic_calls
    final totalKg = result.totalKg;
    // ignore: avoid_dynamic_calls
    final perKmGrams = result.perKmGrams;
    // ignore: avoid_dynamic_calls
    final trees = result.treesEquivalentYear as int;

    // Formata kg com vírgula brasileira (ex.: 88,40).
    final kgStr = totalKg.toStringAsFixed(2).replaceAll('.', ',');

    // gCO₂/km: arredondado para inteiro; "—" se null.
    final String perKmStr;
    if (perKmGrams != null) {
      final rounded = (perKmGrams as dynamic).toDouble().round();
      perKmStr = '$rounded';
    } else {
      perKmStr = '—';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.surfaceRaised,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: context.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: ícone + label + toggle
              Row(
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'EMISSÃO DE CO₂',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  _PeriodToggle(selected: period, onChanged: onPeriodChanged),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Hero number
              Text(
                '$kgStr kg CO₂',
                style: AppTypography.metric(26, color: AppColors.success),
              ),

              const SizedBox(height: AppSpacing.xs),

              // gCO₂/km
              Row(
                children: [
                  Icon(Icons.route_outlined, size: 14, color: context.inkSoft),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'gCO₂/km: $perKmStr',
                    style: AppTypography.body(13, color: context.inkMuted),
                  ),
                ],
              ),

              if (trees > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Para compensar, ~$trees árvore${trees == 1 ? '' : 's'} por ano',
                  style: AppTypography.body(13, color: context.inkMuted),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              // Footnote
              Text(
                'Considera apenas a queima do combustível',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.inkSoft,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PeriodToggle — toggle simples Mês / Ano
// ---------------------------------------------------------------------------

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.selected, required this.onChanged});

  final _Period selected;
  final void Function(_Period) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleChip(
          label: 'Mês',
          selected: selected == _Period.month,
          onTap: () => onChanged(_Period.month),
        ),
        const SizedBox(width: AppSpacing.xs),
        _ToggleChip(
          label: 'Ano',
          selected: selected == _Period.year,
          onTap: () => onChanged(_Period.year),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.success : context.surfaceSunken;
    final fg = selected ? Colors.white : context.inkMuted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.allSm),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: fg, letterSpacing: 0.2),
        ),
      ),
    );
  }
}
