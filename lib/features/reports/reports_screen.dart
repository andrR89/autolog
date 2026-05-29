// Tela de Relatórios do AutoLog — redesign editorial animado.
//
// Estrutura:
//   1. Hero header (brand escuro) com gasto do mês em count-up + delta %
//   2. Seção "Gasto" — BarChart animado (barras crescem na entrada)
//   3. Seção "Consumo" — AreaChart animado (linha desenha + fill lima)
//   4. Seção "Preço/litro" — LineChart minimalista (linha cotação)
//
// Cada seção entra com fade+slide em cascata (StaggeredReveal, ~90ms entre).
// Os gráficos fl_chart re-animam automaticamente quando dados mudam
// via swapAnimationDuration: 800ms / swapAnimationCurve: easeOutCubic.
//
// Providers e funções de agregação NÃO foram alterados.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/expenses/expenses_list_screen.dart'
    show expensesByVehicleProvider;
import 'package:autolog/features/fuel/fuel_history_screen.dart'
    show fuelEntriesByVehicleProvider;
import 'package:autolog/features/recap/recap_banner_gate.dart';
import 'package:autolog/features/reports/monthly_consumption.dart';
import 'package:autolog/features/reports/monthly_price.dart';
import 'package:autolog/features/reports/monthly_spending.dart';
import 'package:autolog/features/reports/reports_providers.dart';
import 'package:autolog/features/reports/widgets/chart_section.dart';
import 'package:autolog/features/reports/widgets/consumption_area_chart.dart';
import 'package:autolog/features/reports/widgets/empty_chart_state.dart';
import 'package:autolog/features/reports/widgets/monthly_hero_metric.dart';
import 'package:autolog/features/reports/widgets/price_line_chart.dart';
import 'package:autolog/features/reports/widgets/spending_bar_chart.dart';
import 'package:autolog/features/reports/widgets/staggered_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Tela de relatórios com animações editoriais para [vehicle].
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendingAsync = ref.watch(monthlySpendingProvider(vehicle.id));
    final consumptionAsync = ref.watch(monthlyConsumptionProvider(vehicle.id));
    final priceAsync = ref.watch(monthlyPriceProvider(vehicle.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.brandInk,
        iconTheme: const IconThemeData(color: AppColors.brandInk),
        titleTextStyle: AppTypography.body(
          18,
          weight: FontWeight.w600,
          color: AppColors.brandInk,
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        // Recap sempre acessível por ✨ no AppBar (3 opções de período),
        // mesmo quando o banner contextual não está visível.
        actions: [
          IconButton(
            tooltip: 'Comparar período',
            icon: const Icon(Icons.compare_arrows_rounded),
            onPressed: () =>
                context.push('/vehicles/${vehicle.id}/reports/compare'),
          ),
          const _RecapMenuAction(),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner Recap contextual — só aparece em fim/início de mês
          // E com dados suficientes (≥3 entries). Esporádico por design.
          SliverToBoxAdapter(child: _RecapBanner(vehicle: vehicle)),

          // Hero metric — gasto do mês corrente com count-up
          SliverToBoxAdapter(
            child: spendingAsync.when(
              loading: _HeroSkeleton.new,
              error: (_, e) => const SizedBox.shrink(),
              data: (data) => MonthlyHeroMetric(
                vehicleNickname: vehicle.nickname,
                monthlyData: data,
              ),
            ),
          ),

          // Separador visual
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // Card "Meus postos" — acesso rápido à agregação por posto
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _MyStationsCard(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // 3 seções de gráfico em cascata
          SliverToBoxAdapter(
            child: _ChartSections(
              spendingAsync: spendingAsync,
              consumptionAsync: consumptionAsync,
              priceAsync: priceAsync,
            ),
          ),

          // Espaço inferior para não colar no nav bar
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.huge)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seções de gráfico com stagger reveal
// ---------------------------------------------------------------------------

class _ChartSections extends StatelessWidget {
  const _ChartSections({
    required this.spendingAsync,
    required this.consumptionAsync,
    required this.priceAsync,
  });

  final AsyncValue<List<MonthlyTotal>> spendingAsync;
  final AsyncValue<List<MonthlyConsumption>> consumptionAsync;
  final AsyncValue<List<MonthlyPrice>> priceAsync;

  @override
  Widget build(BuildContext context) {
    return StaggeredReveal(
      delayStep: const Duration(milliseconds: 90),
      initialDelay: const Duration(milliseconds: 100),
      children: [
        // Seção 1 — Gasto mensal (BarChart)
        _buildSection(
          async: spendingAsync,
          overline: 'Gasto',
          title: 'Por mês',
          overlineColor: AppColors.brand,
          emptyMessage:
              'Cadastre mais abastecimentos e despesas pra ver a evolução do gasto.',
          buildChart: (data) => SpendingBarChart(data: data),
          buildInsight: (data) => _spendingInsight(data),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Seção 2 — Consumo médio (AreaChart com fill lima)
        _buildSection(
          async: consumptionAsync,
          overline: 'Consumo',
          title: 'Média mensal',
          overlineColor: AppColors.success,
          emptyMessage:
              'Registre dois abastecimentos cheios seguidos pra calcular o consumo.',
          buildChart: (data) => ConsumptionAreaChart(data: data),
          buildInsight: (data) => _consumptionInsight(data),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Seção 3 — Preço por litro (LineChart minimalista)
        _buildSection(
          async: priceAsync,
          overline: 'Preço/litro',
          title: 'Evolução',
          overlineColor: context.inkMuted,
          emptyMessage:
              'Cadastre abastecimentos pra ver a variação do preço do combustível.',
          buildChart: (data) => PriceLineChart(data: data),
          buildInsight: (data) => _priceInsight(data),
        ),
      ],
    );
  }

  Widget _buildSection<T>({
    required AsyncValue<List<T>> async,
    required String overline,
    required String title,
    required Color overlineColor,
    required String emptyMessage,
    required Widget Function(List<T>) buildChart,
    required String? Function(List<T>) buildInsight,
  }) {
    return switch (async) {
      AsyncLoading() => _SectionSkeleton(overline: overline, title: title),
      AsyncError() => _SectionError(overline: overline, title: title),
      AsyncData(:final value) when value.isEmpty => ChartSection(
        overline: overline,
        title: title,
        overlineColor: overlineColor,
        chart: EmptyChartState(message: emptyMessage),
      ),
      AsyncData(:final value) => ChartSection(
        overline: overline,
        title: title,
        overlineColor: overlineColor,
        insight: buildInsight(value),
        chart: buildChart(value),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  // --- Insights contextuais ---

  String? _spendingInsight(List<MonthlyTotal> data) {
    if (data.isEmpty) return null;
    final now = DateTime.now();
    final thisBucket = DateTime.utc(now.year, now.month, 1);
    final thisMonth = data.where((d) => d.month == thisBucket).firstOrNull;
    if (thisMonth == null) return null;
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );
    return 'Este mês: ${fmt.format(thisMonth.total.toDouble())}';
  }

  String? _consumptionInsight(List<MonthlyConsumption> data) {
    if (data.isEmpty) return null;
    final last = data.last;
    final fmt = NumberFormat('0.0', 'pt_BR');
    return 'Último: ${fmt.format(last.kmPerLiter.toDouble())} km/L';
  }

  String? _priceInsight(List<MonthlyPrice> data) {
    if (data.isEmpty) return null;
    final last = data.last;
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );
    return 'Último: ${fmt.format(last.pricePerLiter.toDouble())}/L';
  }
}

// ---------------------------------------------------------------------------
// Skeleton do hero — exibido enquanto dados carregam
// ---------------------------------------------------------------------------

class _HeroSkeleton extends StatefulWidget {
  @override
  State<_HeroSkeleton> createState() => _HeroSkeletonState();
}

class _HeroSkeletonState extends State<_HeroSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final alpha = (0.15 + _shimmer.value * 0.12).clamp(0.0, 1.0);
        return Container(
          color: AppColors.brand,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(width: 80, height: 11, alpha: alpha),
              const SizedBox(height: AppSpacing.sm),
              _bar(width: 140, height: 13, alpha: alpha),
              const SizedBox(height: AppSpacing.lg),
              _bar(width: 220, height: 46, alpha: alpha),
              const SizedBox(height: AppSpacing.sm),
              _bar(width: 100, height: 13, alpha: alpha),
            ],
          ),
        );
      },
    );
  }

  Widget _bar({
    required double width,
    required double height,
    required double alpha,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.brandInk.withValues(alpha: alpha),
        borderRadius: AppRadius.allSm,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton de seção — exibido enquanto dados carregam
// ---------------------------------------------------------------------------

class _SectionSkeleton extends StatefulWidget {
  const _SectionSkeleton({required this.overline, required this.title});

  final String overline;
  final String title;

  @override
  State<_SectionSkeleton> createState() => _SectionSkeletonState();
}

class _SectionSkeletonState extends State<_SectionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final alpha = (0.08 + _shimmer.value * 0.08).clamp(0.0, 1.0);
        return Container(
          color: context.surfaceRaised,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(context, width: 48, height: 10, alpha: alpha),
              const SizedBox(height: AppSpacing.xs + 2),
              _bar(context, width: 100, height: 18, alpha: alpha),
              const SizedBox(height: AppSpacing.lg),
              _bar(context, width: double.infinity, height: 180, alpha: alpha),
            ],
          ),
        );
      },
    );
  }

  Widget _bar(
    BuildContext context, {
    required double width,
    required double height,
    required double alpha,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.ink.withValues(alpha: alpha),
        borderRadius: AppRadius.allSm,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado de erro de seção
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Card "Meus postos" — atalho global para a tela de agregação por posto
// ---------------------------------------------------------------------------

class _MyStationsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/stations'),
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceRaised,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: context.hairline),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.surfaceSunken,
                borderRadius: AppRadius.allSm,
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.local_gas_station_outlined,
                  size: 20,
                  color: context.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meus postos',
                    style: AppTypography.body(
                      15,
                      weight: FontWeight.w600,
                      color: context.ink,
                    ),
                  ),
                  Text(
                    'Veja onde você abastece e o preço médio',
                    style: AppTypography.body(12, color: context.inkMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.overline, required this.title});

  final String overline;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ChartSection(
      overline: overline,
      title: title,
      chart: const EmptyChartState(
        message: 'Não foi possível carregar este relatório.\nTente novamente.',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recap — entry points novos (Sprint 6.W.2)
//
// Substitui o `_RecapCard` antigo (gigante, sempre visível) por:
//   - `_RecapBanner`: linha compacta contextual. Só aparece em momentos
//     específicos do mês com dados suficientes (ver recap_banner_gate).
//   - `_RecapMenuAction`: ícone ✨ no AppBar sempre visível, abre menu
//     com 3 opções (mês atual / mês anterior / esta semana).
// ---------------------------------------------------------------------------

class _RecapBanner extends ConsumerWidget {
  const _RecapBanner({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelsAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));
    final expensesAsync = ref.watch(expensesByVehicleProvider(vehicle.id));

    final fuels = fuelsAsync.valueOrNull ?? const <FuelEntry>[];
    final expenses = expensesAsync.valueOrNull ?? const <Expense>[];

    final now = DateTime.now();
    final firstThisMonth = DateTime(now.year, now.month);
    final firstPrevMonth = DateTime(now.year, now.month - 1);

    int countInMonth(DateTime ref) =>
        fuels
            .where((e) => e.date.year == ref.year && e.date.month == ref.month)
            .length +
        expenses
            .where((e) => e.date.year == ref.year && e.date.month == ref.month)
            .length;

    final decision = shouldShowRecapBanner(
      now: now,
      currentMonthEntries: countInMonth(firstThisMonth),
      previousMonthEntries: countInMonth(firstPrevMonth),
    );

    if (decision.decision == RecapShowDecision.hide) {
      // Banner não tem espaço quando não deve ser mostrado.
      return const SizedBox.shrink();
    }

    final period = decision.decision == RecapShowDecision.previousMonth
        ? 'month'
        : 'month'; // ambos usam recap mensal — o gate só muda o label
    final label = decision.decision == RecapShowDecision.previousMonth
        ? 'Seu Recap de ${decision.periodLabel} tá pronto'
        : 'Seu Recap de ${decision.periodLabel} já tem cara';

    // Visual de banner INFORMATIVO (azul-soft) — mais leve que brand-dark,
    // condiz com a natureza esporádica/descobrível do Recap. Ícone do
    // Material (não emoji) pra render confiável em qualquer fonte.
    // Banner edge-to-edge: sem margens externas nem cantos arredondados.
    // Vira faixa horizontal completa entre AppBar e hero metric, sem
    // áreas brancas órfãs nas laterais.
    return Material(
      color: AppColors.infoSoft,
      child: InkWell(
        onTap: () => context.push('/recap?period=$period'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.info,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(
                    14,
                    weight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.info.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecapMenuAction extends StatelessWidget {
  const _RecapMenuAction();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Recap',
      icon: const Icon(Icons.auto_awesome_rounded),
      onSelected: (route) => context.push(route),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: '/recap?period=month',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_month_outlined),
            title: Text('Recap deste mês'),
          ),
        ),
        PopupMenuItem(
          value: '/recap?period=week',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.calendar_view_week_outlined),
            title: Text('Esta semana'),
          ),
        ),
      ],
    );
  }
}
