// Tela "Comparar período" — Sprint 6.KK.
//
// Layout:
//   1. AppBar "Comparar período" com toggle [Mês] [Ano]
//   2. 2 colunas de cards lado a lado (período atual x anterior)
//   3. Barras horizontais comparativas (fl_chart BarChart)
//   4. Deltas % coloridos: verde = melhorou, vermelho = piorou
//      (atenção: consumo L/km MAIOR é PIOR → cor invertida)
//   5. Botão "Período personalizado" → DateRangePicker
//   6. Empty state quando não há dados suficientes

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/reports/compare/period_compare_models.dart';
import 'package:autolog/features/reports/compare/period_compare_providers.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

class PeriodCompareScreen extends ConsumerStatefulWidget {
  const PeriodCompareScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<PeriodCompareScreen> createState() =>
      _PeriodCompareScreenState();
}

class _PeriodCompareScreenState extends ConsumerState<PeriodCompareScreen> {
  PeriodCompareMode _mode = PeriodCompareMode.month;

  // Ranges para o modo custom
  DateTime? _customCurrFrom;
  DateTime? _customCurrTo;
  DateTime? _customPrevFrom;
  DateTime? _customPrevTo;

  PeriodCompareArgs get _args {
    if (_mode == PeriodCompareMode.custom &&
        _customCurrFrom != null &&
        _customCurrTo != null &&
        _customPrevFrom != null &&
        _customPrevTo != null) {
      return PeriodCompareArgs(
        vehicleId: widget.vehicle.id,
        mode: PeriodCompareMode.custom,
        currentFrom: _customCurrFrom,
        currentTo: _customCurrTo,
        previousFrom: _customPrevFrom,
        previousTo: _customPrevTo,
      );
    }
    return PeriodCompareArgs(
      vehicleId: widget.vehicle.id,
      mode: _mode == PeriodCompareMode.custom ? PeriodCompareMode.month : _mode,
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    // Primeiro período (atual)
    final currRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Período atual',
      saveText: 'Próximo',
    );
    if (!context.mounted || currRange == null) return;

    // Segundo período (anterior)
    final prevRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Período anterior',
      saveText: 'Comparar',
    );
    if (!context.mounted || prevRange == null) return;

    setState(() {
      _mode = PeriodCompareMode.custom;
      _customCurrFrom = currRange.start.toUtc();
      _customCurrTo = DateTime.utc(
        currRange.end.year,
        currRange.end.month,
        currRange.end.day,
        23,
        59,
        59,
      );
      _customPrevFrom = prevRange.start.toUtc();
      _customPrevTo = DateTime.utc(
        prevRange.end.year,
        prevRange.end.month,
        prevRange.end.day,
        23,
        59,
        59,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(periodCompareProvider(_args));

    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: Text(
          'Comparar período',
          style: AppTypography.body(
            18,
            weight: FontWeight.w600,
            color: AppColors.brandInk,
          ),
        ),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.brandInk,
        iconTheme: const IconThemeData(color: AppColors.brandInk),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          // Toggle Mês / Ano
          _ModeToggle(
            mode: _mode == PeriodCompareMode.custom
                ? PeriodCompareMode.month
                : _mode,
            onChanged: (m) => setState(() {
              _mode = m;
              // Resetar custom quando muda para modo fixo
              if (m != PeriodCompareMode.custom) {
                _customCurrFrom = null;
                _customCurrTo = null;
                _customPrevFrom = null;
                _customPrevTo = null;
              }
            }),
          ),

          // Conteúdo
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(error: e.toString()),
              data: (data) => _CompareBody(
                data: data,
                onCustomRange: () => _pickCustomRange(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle Mês / Ano
// ---------------------------------------------------------------------------

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final PeriodCompareMode mode;
  final void Function(PeriodCompareMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brand,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Mês',
            selected: mode == PeriodCompareMode.month,
            onTap: () => onChanged(PeriodCompareMode.month),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Tab(
            label: 'Ano',
            selected: mode == PeriodCompareMode.year,
            onTap: () => onChanged(PeriodCompareMode.year),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.standard,
        curve: AppMotion.standardCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: AppRadius.allSm,
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.brandInk.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body(
            14,
            weight: FontWeight.w600,
            color: selected ? AppColors.accentInk : AppColors.brandInk,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Corpo principal
// ---------------------------------------------------------------------------

class _CompareBody extends StatelessWidget {
  const _CompareBody({required this.data, required this.onCustomRange});

  final PeriodCompareData data;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    final hasAnyData =
        data.current.entriesCount > 0 || data.previous.entriesCount > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cards lado a lado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PeriodCard(
                  summary: data.current,
                  isHighlighted: true,
                  data: data,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PeriodCard(
                  summary: data.previous,
                  isHighlighted: false,
                  data: data,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          if (!hasAnyData) ...[
            _EmptyState(),
          ] else ...[
            // Barras comparativas
            _CompareSection(
              label: 'Gasto total',
              currentValue: data.current.totalSpent.toDouble(),
              previousValue: data.previous.totalSpent.toDouble(),
              currentLabel: data.current.label,
              previousLabel: data.previous.label,
              formatValue: _formatCurrency,
              deltaPercent: data.totalSpentDeltaPercent,
              lowerIsBetter: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            _CompareSection(
              label: 'Litros abastecidos',
              currentValue: data.current.totalLiters.toDouble(),
              previousValue: data.previous.totalLiters.toDouble(),
              currentLabel: data.current.label,
              previousLabel: data.previous.label,
              formatValue: (v) => '${_formatDecimal(v)} L',
              deltaPercent: data.litersDeltaPercent,
              lowerIsBetter: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            _CompareSection(
              label: 'Distância',
              currentValue: data.current.totalKm.toDouble(),
              previousValue: data.previous.totalKm.toDouble(),
              currentLabel: data.current.label,
              previousLabel: data.previous.label,
              formatValue: (v) => '${v.round()} km',
              deltaPercent: null, // distância: mostramos delta absoluto
              deltaAbsolute: data.distanceDelta != 0
                  ? '${data.distanceDelta > 0 ? '+' : ''}${data.distanceDelta} km'
                  : null,
              lowerIsBetter: false,
            ),

            if (data.current.avgConsumption != null ||
                data.previous.avgConsumption != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _CompareSection(
                label: 'Consumo médio',
                currentValue: data.current.avgConsumption?.toDouble() ?? 0,
                previousValue: data.previous.avgConsumption?.toDouble() ?? 0,
                currentLabel: data.current.label,
                previousLabel: data.previous.label,
                formatValue: (v) => v > 0 ? '${_formatDecimal(v)} km/L' : '—',
                deltaPercent: null,
                deltaAbsolute: _consumoDeltaLabel(data.avgConsumptionDelta),
                // Consumo maior é MELHOR para o usuário (percorre mais por litro)
                lowerIsBetter: false,
              ),
            ],
          ],

          const SizedBox(height: AppSpacing.xxl),

          // Botão período personalizado
          OutlinedButton.icon(
            onPressed: onCustomRange,
            icon: const Icon(Icons.date_range_outlined, size: 18),
            label: const Text('Período personalizado'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              side: const BorderSide(color: AppColors.brand),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              textStyle: AppTypography.body(14, weight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  String? _consumoDeltaLabel(Decimal? delta) {
    if (delta == null) return null;
    if (delta == Decimal.zero) return null;
    final prefix = delta > Decimal.zero ? '+' : '';
    return '$prefix${_formatDecimal(delta.toDouble())} km/L';
  }

  static String _formatCurrency(double v) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    ).format(v);
  }

  static String _formatDecimal(double v) {
    return NumberFormat('0.0', 'pt_BR').format(v);
  }
}

// ---------------------------------------------------------------------------
// Card de período
// ---------------------------------------------------------------------------

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.summary,
    required this.isHighlighted,
    required this.data,
  });

  final PeriodSummary summary;
  final bool isHighlighted;
  final PeriodCompareData data;

  @override
  Widget build(BuildContext context) {
    final fmtCurr = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 0,
    );
    final fmtDec = NumberFormat('0.0', 'pt_BR');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.brand : context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: isHighlighted ? null : Border.all(color: context.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label do período
          Text(
            isHighlighted ? 'Atual' : 'Anterior',
            style: AppTypography.body(
              10,
              weight: FontWeight.w600,
              letterSpacing: 0.8,
              color: isHighlighted
                  ? AppColors.brandInk.withValues(alpha: 0.6)
                  : context.inkMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary.label,
            style: AppTypography.body(
              13,
              weight: FontWeight.w600,
              color: isHighlighted ? AppColors.brandInk : context.ink,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Gasto
          _MetricRow(
            icon: Icons.payments_outlined,
            value: fmtCurr.format(summary.totalSpent.toDouble()),
            label: 'gasto',
            highlighted: isHighlighted,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Litros
          _MetricRow(
            icon: Icons.local_gas_station_outlined,
            value: '${fmtDec.format(summary.totalLiters.toDouble())} L',
            label: 'litros',
            highlighted: isHighlighted,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Km
          _MetricRow(
            icon: Icons.speed_outlined,
            value: '${summary.totalKm} km',
            label: 'distância',
            highlighted: isHighlighted,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Consumo
          _MetricRow(
            icon: Icons.eco_outlined,
            value: summary.avgConsumption != null
                ? '${fmtDec.format(summary.avgConsumption!.toDouble())} km/L'
                : '—',
            label: 'consumo',
            highlighted: isHighlighted,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.value,
    required this.label,
    required this.highlighted,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlighted;

  Color _ink(bool highlight) => highlight ? AppColors.brandInk : AppColors.ink;
  Color _inkMuted(bool highlight) => highlight
      ? AppColors.brandInk.withValues(alpha: 0.5)
      : AppColors.inkMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _inkMuted(highlighted)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body(
              13,
              weight: FontWeight.w600,
              color: _ink(highlighted),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Seção de comparação com barra fl_chart
// ---------------------------------------------------------------------------

class _CompareSection extends StatelessWidget {
  const _CompareSection({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.currentLabel,
    required this.previousLabel,
    required this.formatValue,
    required this.lowerIsBetter,
    this.deltaPercent,
    this.deltaAbsolute,
  });

  final String label;
  final double currentValue;
  final double previousValue;
  final String currentLabel;
  final String previousLabel;
  final String Function(double) formatValue;
  final Decimal? deltaPercent;
  final String? deltaAbsolute;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      currentValue,
      previousValue,
    ].reduce((a, b) => a > b ? a : b);
    final hasData = maxValue > 0;

    // Determinar cor do delta
    Color? deltaColor;
    final effectiveDelta = deltaPercent;
    if (effectiveDelta != null) {
      final isPositive = effectiveDelta > Decimal.zero;
      // lowerIsBetter: positivo (aumentou) = ruim; negativo (diminuiu) = bom
      // !lowerIsBetter: positivo (aumentou) = bom; negativo (diminuiu) = ruim
      if (lowerIsBetter) {
        deltaColor = isPositive ? AppColors.danger : AppColors.success;
      } else {
        deltaColor = isPositive ? AppColors.success : AppColors.danger;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título + delta
        Row(
          children: [
            Text(
              label,
              style: AppTypography.body(
                14,
                weight: FontWeight.w600,
                color: context.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (effectiveDelta != null) ...[
              _DeltaBadge(
                text:
                    '${effectiveDelta > Decimal.zero ? '+' : ''}${NumberFormat('0.0', 'pt_BR').format(effectiveDelta.toDouble())}%',
                color: deltaColor ?? context.inkMuted,
              ),
            ] else if (deltaAbsolute != null) ...[
              _DeltaBadge(
                text: deltaAbsolute!,
                color: deltaColor ?? context.inkMuted,
              ),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        if (!hasData) ...[
          Text(
            'Sem dados neste período',
            style: AppTypography.body(12, color: context.inkMuted),
          ),
        ] else ...[
          // Barra período atual
          _Bar(
            label: currentLabel,
            value: currentValue,
            maxValue: maxValue,
            formatted: formatValue(currentValue),
            color: AppColors.brand,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Barra período anterior
          _Bar(
            label: previousLabel,
            value: previousValue,
            maxValue: maxValue,
            formatted: previousValue > 0
                ? formatValue(previousValue)
                : 'Sem dados',
            color: AppColors.inkSoft,
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.formatted,
    required this.color,
  });

  final String label;
  final double value;
  final double maxValue;
  final String formatted;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: AppTypography.body(11, color: context.inkMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Track
                      Container(
                        height: 20,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: context.surfaceSunken,
                          borderRadius: AppRadius.allSm,
                        ),
                      ),
                      // Fill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: AppMotion.emphasizedCurve,
                        height: 20,
                        width: constraints.maxWidth * ratio,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: AppRadius.allSm,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 80,
              child: Text(
                formatted,
                style: AppTypography.body(
                  11,
                  weight: FontWeight.w600,
                  color: context.ink,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allSm,
      ),
      child: Text(
        text,
        style: AppTypography.body(11, weight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: 56,
              color: context.inkSoft,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhum dado para comparar',
              style: AppTypography.body(
                16,
                weight: FontWeight.w600,
                color: context.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Registre abastecimentos e despesas\npara ver a comparação entre períodos.',
              style: AppTypography.body(13, color: context.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado de erro
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Não foi possível carregar os dados.',
              style: AppTypography.body(14, color: context.ink),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
