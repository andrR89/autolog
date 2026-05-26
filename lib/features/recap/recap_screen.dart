// recap_screen.dart — Tela Recap estilo Spotify Wrapped.
//
// PageView vertical full-screen com 5-7 slides de destaque.
// Lê dados de TODOS os veículos do usuário (recap agregado por conta).
//
// Spec: docs/specs/sprint-6.V-recap-wrapped.md
// TODO: compartilhamento via share_plus (package não disponível no MVP).

import 'dart:async';

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/recap/recap_data.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Provider — carrega todos os fuels e expenses de todos os veículos do user
// ---------------------------------------------------------------------------

/// Par (fuels, expenses) de todos os veículos do usuário atual.
final _allEntriesProvider =
    FutureProvider.autoDispose<({List<FuelEntry> fuels, List<Expense> expenses})>(
  (ref) async {
    final userId = ref.watch(currentUserIdProvider);
    final vehicleRepo = ref.watch(vehicleRepositoryProvider);
    final fuelRepo = ref.watch(fuelEntryRepositoryProvider);
    final expenseRepo = ref.watch(expenseRepositoryProvider);

    final vehicles = await vehicleRepo.listByUser(userId);
    final fuels = <FuelEntry>[];
    final expenses = <Expense>[];

    for (final v in vehicles) {
      fuels.addAll(await fuelRepo.listByVehicle(v.id));
      expenses.addAll(await expenseRepo.listByVehicle(v.id));
    }

    return (fuels: fuels, expenses: expenses);
  },
);

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

/// Tela de Recap mensal/semanal estilo Spotify Wrapped.
///
/// [period] vem da query param da rota (/recap?period=week|month).
class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key, required this.period});

  final RecapPeriod period;

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  final _controller = PageController();
  Timer? _autoAdvance;
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    _autoAdvance?.cancel();
    super.dispose();
  }

  void _startAutoAdvance(int totalPages) {
    _autoAdvance?.cancel();
    _autoAdvance = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = _currentPage + 1;
      if (next < totalPages) {
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _autoAdvance?.cancel();
      }
    });
  }

  List<Widget> _buildSlides(RecapData data) {
    final slides = <Widget>[];

    // 1. Hero
    slides.add(_HeroSlide(period: data.period, start: data.start, end: data.end));

    // 2. Total gasto
    slides.add(
      _TotalSpentSlide(
        totalSpent: data.totalSpent,
        fuelCount: data.fuelEntriesCount,
        expenseCount: data.expensesCount,
      ),
    );

    // 3. Km rodados
    slides.add(_KmSlide(kmDriven: data.kmDriven));

    // 4. Consumo médio (só se tiver dados)
    if (data.avgConsumptionKmL != null) {
      slides.add(_ConsumptionSlide(avgKmL: data.avgConsumptionKmL!));
    } else if (data.fuelEntriesCount > 0) {
      slides.add(const _ConsumptionEmptySlide());
    }

    // 5. Preços (só se tiver fuels)
    if (data.cheapestPricePerLiter != null &&
        data.mostExpensivePricePerLiter != null) {
      slides.add(
        _PriceSlide(
          cheapest: data.cheapestPricePerLiter!,
          mostExpensive: data.mostExpensivePricePerLiter!,
        ),
      );
    }

    // 6. Posto preferido (só se identificado)
    if (data.favoriteStation != null) {
      slides.add(_FavoriteStationSlide(station: data.favoriteStation!));
    }

    // 7. Categoria top (só se tiver despesas)
    if (data.topExpenseCategory != null) {
      slides.add(_TopCategorySlide(category: data.topExpenseCategory!));
    }

    return slides;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(_allEntriesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.brand,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.brandInk),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandInk),
        ),
        error: (e, _) => Center(
          child: Text(
            'Não foi possível carregar o Recap.',
            style: AppTypography.body(16, color: AppColors.brandInk),
          ),
        ),
        data: (entries) {
          final data = computeRecap(
            period: widget.period,
            now: DateTime.now().toUtc(),
            fuels: entries.fuels,
            expenses: entries.expenses,
          );
          final slides = _buildSlides(data);

          // Inicia auto-avanço após o primeiro build com dados.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _autoAdvance == null) {
              _startAutoAdvance(slides.length);
            }
          });

          return Stack(
            children: [
              PageView.builder(
                controller: _controller,
                scrollDirection: Axis.vertical,
                itemCount: slides.length,
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                },
                itemBuilder: (context, i) => slides[i],
              ),
              // Indicador de páginas vertical à direita
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _PageIndicator(
                    count: slides.length,
                    current: _currentPage,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Indicador de páginas vertical
// ---------------------------------------------------------------------------

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 3),
          width: 6,
          height: active ? 20 : 6,
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent
                : AppColors.brandInk.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide base — fundo gradient brand-dark, números enormes
// ---------------------------------------------------------------------------

/// Wrapper de slide full-screen com gradiente brand e fade-in na entrada.
class _SlideBase extends StatefulWidget {
  const _SlideBase({required this.child});

  final Widget child;

  @override
  State<_SlideBase> createState() => _SlideBaseState();
}

class _SlideBaseState extends State<_SlideBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandSoft],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: widget.child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 1 — Hero
// ---------------------------------------------------------------------------

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({
    required this.period,
    required this.start,
    required this.end,
  });

  final RecapPeriod period;
  final DateTime start;
  final DateTime end;

  String get _emoji => period == RecapPeriod.week ? '🚀' : '🌟';

  String get _title =>
      period == RecapPeriod.week ? 'Sua semana\nem movimento' : 'Seu mês\nem movimento';

  String get _periodLabel {
    final fmt = DateFormat('d MMM', 'pt_BR');
    if (period == RecapPeriod.week) {
      return '${fmt.format(start)} a ${fmt.format(end)}';
    }
    return DateFormat('MMMM y', 'pt_BR').format(start);
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              _title,
              style: AppTypography.display(
                48,
                weight: FontWeight.w700,
                color: AppColors.brandInk,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _periodLabel,
              style: AppTypography.body(
                18,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 2 — Total gasto
// ---------------------------------------------------------------------------

class _TotalSpentSlide extends StatelessWidget {
  const _TotalSpentSlide({
    required this.totalSpent,
    required this.fuelCount,
    required this.expenseCount,
  });

  final Decimal totalSpent;
  final int fuelCount;
  final int expenseCount;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );
    return _SlideBase(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você gastou',
              style: AppTypography.body(
                20,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              fmt.format(totalSpent.toDouble()),
              style: AppTypography.metric(
                56,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'em $fuelCount abastecimento${fuelCount != 1 ? 's' : ''}'
              ' + $expenseCount despesa${expenseCount != 1 ? 's' : ''}',
              style: AppTypography.body(
                16,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 3 — Km rodados
// ---------------------------------------------------------------------------

class _KmSlide extends StatelessWidget {
  const _KmSlide({required this.kmDriven});

  final int kmDriven;

  String get _equivalencia {
    if (kmDriven >= 440) {
      final trips = (kmDriven / 440).toStringAsFixed(1);
      return '≈ $trips vez${double.parse(trips) > 1.5 ? 'es' : ''} SP–RJ';
    }
    return 'no total';
  }

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🚗', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Você rodou',
              style: AppTypography.body(
                20,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$kmDriven km',
              style: AppTypography.metric(
                64,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _equivalencia,
              style: AppTypography.body(
                18,
                color: AppColors.brandInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 4a — Consumo médio (com dados)
// ---------------------------------------------------------------------------

class _ConsumptionSlide extends StatelessWidget {
  const _ConsumptionSlide({required this.avgKmL});

  final Decimal avgKmL;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('0.0', 'pt_BR');
    return _SlideBase(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⛽', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Consumo médio',
              style: AppTypography.body(
                20,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${fmt.format(avgKmL.toDouble())} km/L',
              style: AppTypography.metric(
                64,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 4b — Consumo (sem dados suficientes)
// ---------------------------------------------------------------------------

class _ConsumptionEmptySlide extends StatelessWidget {
  const _ConsumptionEmptySlide();

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⛽', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Consumo médio',
              style: AppTypography.body(
                20,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Abasteça mais uma vez para calcular o consumo do período.',
              style: AppTypography.display(
                28,
                weight: FontWeight.w600,
                color: AppColors.brandInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 5 — Preços
// ---------------------------------------------------------------------------

class _PriceSlide extends StatelessWidget {
  const _PriceSlide({required this.cheapest, required this.mostExpensive});

  final Decimal cheapest;
  final Decimal mostExpensive;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );
    return _SlideBase(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💲', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Preço por litro',
              style: AppTypography.body(
                20,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Mais barato',
              style: AppTypography.body(
                14,
                color: AppColors.brandInk.withValues(alpha: 0.5),
              ),
            ),
            Text(
              fmt.format(cheapest.toDouble()),
              style: AppTypography.metric(
                48,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Mais caro',
              style: AppTypography.body(
                14,
                color: AppColors.brandInk.withValues(alpha: 0.5),
              ),
            ),
            Text(
              fmt.format(mostExpensive.toDouble()),
              style: AppTypography.metric(
                48,
                color: AppColors.brandInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 6 — Posto preferido
// ---------------------------------------------------------------------------

class _FavoriteStationSlide extends StatelessWidget {
  const _FavoriteStationSlide({required this.station});

  final String station;

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⭐', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Seu posto favorito',
              style: AppTypography.body(
                20,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              station,
              style: AppTypography.display(
                40,
                weight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Slide 7 — Categoria top
// ---------------------------------------------------------------------------

class _TopCategorySlide extends StatelessWidget {
  const _TopCategorySlide({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return _SlideBase(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Você gastou mais com',
              style: AppTypography.body(
                20,
                color: AppColors.brandInk.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              category,
              style: AppTypography.display(
                48,
                weight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
