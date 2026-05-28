import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_form_validators.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/reports/fuel_economy_comparator.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Tela de comparação etanol × gasolina para veículos flex.
///
/// Mostra consumo real do histórico, pré-preenche preços do último
/// abastecimento e recomputa em tempo real ao alterar os campos.
class FuelEconomyScreen extends ConsumerStatefulWidget {
  const FuelEconomyScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<FuelEconomyScreen> createState() => _FuelEconomyScreenState();
}

class _FuelEconomyScreenState extends ConsumerState<FuelEconomyScreen> {
  final _gasolinaController = TextEditingController();
  final _etanolController = TextEditingController();

  // Rastreia se o valor foi pré-preenchido do histórico.
  bool _gasolinaFromHistory = false;
  bool _etanolFromHistory = false;

  // Preços atuais (null = campo inválido).
  Decimal? _gasolinaPrice;
  Decimal? _etanolPrice;

  // Flag para evitar double-init.
  bool _initialized = false;

  @override
  void dispose() {
    _gasolinaController.dispose();
    _etanolController.dispose();
    super.dispose();
  }

  void _initializeFromEntries(List entries) {
    if (_initialized) return;
    _initialized = true;

    final gPrice = lastPriceFor(entries.cast(), FuelType.gasolina);
    final ePrice = lastPriceFor(entries.cast(), FuelType.etanol);

    if (gPrice != null) {
      _gasolinaController.text = _formatDecimalPtBr(gPrice);
      _gasolinaPrice = gPrice;
      _gasolinaFromHistory = true;
    }
    if (ePrice != null) {
      _etanolController.text = _formatDecimalPtBr(ePrice);
      _etanolPrice = ePrice;
      _etanolFromHistory = true;
    }
  }

  /// Formata Decimal para exibição pt-BR (ex: 5,99).
  String _formatDecimalPtBr(Decimal value) {
    return value.toString().replaceAll('.', ',');
  }

  void _onGasolinaChanged(String text) {
    setState(() {
      try {
        _gasolinaPrice = parseDecimalPtBr(text);
      } catch (_) {
        _gasolinaPrice = null;
      }
    });
  }

  void _onEtanolChanged(String text) {
    setState(() {
      try {
        _etanolPrice = parseDecimalPtBr(text);
      } catch (_) {
        _etanolPrice = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final entriesAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));

    return entriesAsync.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(child: Text('Erro ao carregar histórico.')),
      ),
      data: (entries) {
        // Pré-preenche na primeira vez que os dados chegam.
        _initializeFromEntries(entries);

        final gasolinaEconomy =
            computeFuelEconomy(entries, FuelType.gasolina);
        final etanolEconomy = computeFuelEconomy(entries, FuelType.etanol);

        FuelComparison? comparison;
        if (_gasolinaPrice != null && _etanolPrice != null) {
          comparison = compareFuels(
            gasolinaPricePerLiter: _gasolinaPrice!,
            etanolPricePerLiter: _etanolPrice!,
            historicalEntries: entries,
          );
        }

        return Scaffold(
          appBar: _buildAppBar(context),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _PricesCard(
                gasolinaController: _gasolinaController,
                etanolController: _etanolController,
                gasolinaFromHistory: _gasolinaFromHistory,
                etanolFromHistory: _etanolFromHistory,
                onGasolinaChanged: _onGasolinaChanged,
                onEtanolChanged: _onEtanolChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              _ConsumptionCard(
                gasolinaEconomy: gasolinaEconomy,
                etanolEconomy: etanolEconomy,
              ),
              const SizedBox(height: AppSpacing.md),
              if (comparison != null)
                _RecommendationCard(comparison: comparison)
              else
                const _RecommendationPlaceholder(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text('Etanol × Gasolina'),
    );
  }
}

// ============================================================================
// Card: Preços
// ============================================================================

class _PricesCard extends StatelessWidget {
  const _PricesCard({
    required this.gasolinaController,
    required this.etanolController,
    required this.gasolinaFromHistory,
    required this.etanolFromHistory,
    required this.onGasolinaChanged,
    required this.onEtanolChanged,
  });

  final TextEditingController gasolinaController;
  final TextEditingController etanolController;
  final bool gasolinaFromHistory;
  final bool etanolFromHistory;
  final ValueChanged<String> onGasolinaChanged;
  final ValueChanged<String> onEtanolChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('PREÇOS DO DIA'),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: gasolinaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: r'Gasolina (R$/L)',
              helperText: gasolinaFromHistory
                  ? 'Pré-preenchido com o último abastecimento'
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: onGasolinaChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: etanolController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: r'Etanol (R$/L)',
              helperText: etanolFromHistory
                  ? 'Pré-preenchido com o último abastecimento'
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: onEtanolChanged,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Card: Consumo
// ============================================================================

class _ConsumptionCard extends StatelessWidget {
  const _ConsumptionCard({
    required this.gasolinaEconomy,
    required this.etanolEconomy,
  });

  final FuelEconomy? gasolinaEconomy;
  final FuelEconomy? etanolEconomy;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('SEU CONSUMO'),
          const SizedBox(height: AppSpacing.md),
          _ConsumptionRow(
            label: 'Gasolina',
            economy: gasolinaEconomy,
            fallback: '12,0',
            color: AppColors.fuelGasoline,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ConsumptionRow(
            label: 'Etanol',
            economy: etanolEconomy,
            fallback: '8,4',
            color: AppColors.fuelEthanol,
          ),
        ],
      ),
    );
  }
}

class _ConsumptionRow extends StatelessWidget {
  const _ConsumptionRow({
    required this.label,
    required this.economy,
    required this.fallback,
    required this.color,
  });

  final String label;
  final FuelEconomy? economy;
  final String fallback;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (economy != null) {
      final kmL = _fmtKmL(economy!.kmPerLiter);
      final count = economy!.basedOnEntries;
      return Row(
        children: [
          _Dot(color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$label: $kmL km/L ($count abastecimentos)',
              style: AppTypography.body(14),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _Dot(color: color.withAlpha(100)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Sem dados — usando $fallback km/L estimado',
            style: AppTypography.body(14, color: context.inkMuted),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: context.surfaceSunken,
            borderRadius: AppRadius.allSm,
          ),
          child: Text(
            'estimativa',
            style: AppTypography.body(
              11,
              weight: FontWeight.w600,
              color: context.inkMuted,
            ),
          ),
        ),
      ],
    );
  }

  String _fmtKmL(Decimal value) {
    return NumberFormat('#,##0.0', 'pt_BR').format(value.toDouble());
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================================
// Card: Recomendação
// ============================================================================

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.comparison});

  final FuelComparison comparison;

  @override
  Widget build(BuildContext context) {
    final isEtanol = comparison.bestChoice == FuelType.etanol;
    final bgColor = isEtanol ? AppColors.successSoft : AppColors.infoSoft;
    final accentColor = isEtanol ? AppColors.success : AppColors.info;
    final label = isEtanol ? 'Etanol compensa' : 'Gasolina compensa';
    final icon = isEtanol
        ? Icons.eco_outlined
        : Icons.local_gas_station_outlined;

    final currFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 4,
    );

    final savingsStr = NumberFormat('#,##0.0', 'pt_BR')
        .format(comparison.savingsPercent.toDouble());

    final gStr = currFmt.format(comparison.gasolinaCostPerKm.toDouble());
    final eStr = currFmt.format(comparison.etanolCostPerKm.toDouble());
    final versusText =
        isEtanol ? '$eStr/km vs $gStr/km' : '$gStr/km vs $eStr/km';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: accentColor.withAlpha(60)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.display(
                    22,
                    weight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            versusText,
            style: AppTypography.body(
              14,
              weight: FontWeight.w500,
              color: accentColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Economia de $savingsStr% por km rodado',
            style: AppTypography.body(13, color: accentColor),
          ),
        ],
      ),
    );
  }
}

class _RecommendationPlaceholder extends StatelessWidget {
  const _RecommendationPlaceholder();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('RECOMENDAÇÃO'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Preencha os preços acima para ver a recomendação.',
            style: AppTypography.body(14, color: context.inkMuted),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Componentes internos reutilizáveis
// ============================================================================

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.inkMuted,
            letterSpacing: 1.4,
          ),
    );
  }
}
