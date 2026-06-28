// Tela do veículo — "casa" do carro.
//
// Mudança em relação ao layout flat anterior: agora é um **dashboard
// editorial**. O cabeçalho hero conta a história (nickname, combustível,
// placa, métrica grande de consumo + stats do mês corrente), e a lista
// de abastecimentos vira uma timeline com grupos por mês e cards mais
// quietos.
//
// Anatomia visual:
//
//   ┌── SliverAppBar (transparente até scroll, sólida depois) ──┐
//   │  ← Civic                          🔔  💲  📊  ✏️           │
//   ├──────────────────────────────────────────────────────────┤
//   │  [Hero header — painel brand + faixa de stats do mês]      │
//   ├──────────────────────────────────────────────────────────┤
//   │  Histórico                                                  │
//   │  Maio 2026                                                  │
//   │  ┌ card abastecimento ┐                                     │
//   │  ┌ card abastecimento ┐                                     │
//   │  Abril 2026                                                 │
//   │  ┌ card abastecimento ┐                                     │
//   └──────────────────────────────────────────────────────────┘
//
// Reuso: PlateStrip, FuelTypeStyle do B1; hero usa typography.dart
// tokens. Cards usam FuelEntryCard novo, embalados em Dismissible
// (mesmo padrão de VehicleCard / VehiclesListScreen).
//
// Sem mudanças de navegação: AppBar mantém os 4 ícones em ordem
// (Lembretes, Despesas, Relatórios, Editar) e FAB extended manda
// para o formulário.

import 'dart:async';

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/dashed_frame.dart';
import 'package:autolog/core/design/widgets/responsive_body.dart';
import 'package:autolog/core/design/widgets/skeleton.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/services/consumption_calculator.dart';
import 'package:autolog/features/fuel/filters/fuel_filter_providers.dart';
import 'package:autolog/features/fuel/filters/fuel_filter_state.dart';
import 'package:autolog/features/fuel/fuel_entry_saver.dart';
import 'package:autolog/features/fuel/fuel_history_helpers.dart';
import 'package:autolog/features/fuel/widgets/favorite_station_card.dart';
import 'package:autolog/features/fuel/widgets/fuel_entry_card.dart';
import 'package:autolog/features/fuel/widgets/vehicle_hero_header.dart';
import 'package:autolog/features/insights/co2/widgets/co2_card.dart';
import 'package:autolog/features/reports/widgets/cost_per_km_card.dart';
import 'package:autolog/features/reports/widgets/trend_card.dart';
import 'package:autolog/features/vehicles/widgets/fipe_history_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Provider reativo para a lista de abastecimentos de um veículo.
///
/// Emite a cada mudança no banco local (Drift watch).
final fuelEntriesByVehicleProvider =
    StreamProvider.family<List<FuelEntry>, String>((ref, vehicleId) {
      final repo = ref.watch(fuelEntryRepositoryProvider);
      return repo.watchByVehicle(vehicleId);
    });

/// Tela do veículo. Entry point: `/vehicles/:vehicleId`.
class FuelHistoryScreen extends ConsumerStatefulWidget {
  const FuelHistoryScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<FuelHistoryScreen> createState() => _FuelHistoryScreenState();
}

class _FuelHistoryScreenState extends ConsumerState<FuelHistoryScreen> {
  late final ScrollController _scrollController;

  /// True quando o usuário rolou o suficiente para o painel hero sair de
  /// vista; nesse momento a AppBar ganha fundo sólido + título visível.
  bool _appBarSealed = false;

  /// Paginação lazy: número de entradas visíveis da timeline.
  /// Inicia em [_kPageSize]; incrementa ao chegar no fim da lista.
  static const int _kPageSize = 25;
  int _visibleCount = _kPageSize;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    // Threshold ~ topo do hero (~80px). Não tem que ser exato; só queremos
    // a AppBar selar quando o conteúdo abaixo já dominou a tela.
    final shouldSeal = _scrollController.hasClients
        ? _scrollController.offset > 80
        : false;
    if (shouldSeal != _appBarSealed) {
      setState(() => _appBarSealed = shouldSeal);
    }

    // Paginação: ao chegar a 200px do fim da lista, carrega mais 25 entradas.
    // Usa a lista filtrada como referência de total.
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= maxScroll - 200) {
        final filteredAsync = ref.read(
          filteredFuelEntriesProvider(widget.vehicle.id),
        );
        final totalEntries = filteredAsync.value?.length ?? 0;
        if (_visibleCount < totalEntries) {
          setState(() => _visibleCount += _kPageSize);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;

    // Usamos o stream completo para o hero/stats (cálculo de consumo sagrado)
    // e o filtrado para a timeline.
    final allEntriesAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));
    final filteredAsync = ref.watch(filteredFuelEntriesProvider(vehicle.id));
    final filterState = ref.watch(fuelFilterStateProvider(vehicle.id));

    // Reseta paginação se a lista filtrada mudou de tamanho.
    filteredAsync.whenData((entries) {
      if (entries.length < _visibleCount) {
        _visibleCount = _kPageSize;
      }
    });

    // Paginação: ao chegar ao fim, incrementa no listener (usa lista filtrada).
    // (Atualizado em _onScroll via filteredAsync)

    return Scaffold(
      body: allEntriesAsync.when(
        loading: () => _ScaffoldedBody(
          vehicle: vehicle,
          appBarSealed: _appBarSealed,
          filterState: filterState,
          child: const _FuelHistorySkeleton(),
        ),
        error: (_, _) => _ScaffoldedBody(
          vehicle: vehicle,
          appBarSealed: _appBarSealed,
          filterState: filterState,
          child: _ErrorState(
            onRetry: () =>
                ref.invalidate(fuelEntriesByVehicleProvider(vehicle.id)),
          ),
        ),
        data: (allEntries) {
          final filteredEntries = filteredAsync.value ?? const [];
          return _DataBody(
            vehicle: vehicle,
            allEntries: allEntries,
            filteredEntries: filteredEntries,
            scrollController: _scrollController,
            appBarSealed: _appBarSealed,
            filterState: filterState,
            visibleCount: filteredEntries.length <= _kPageSize
                ? null
                : _visibleCount,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/${vehicle.id}/fuel/new'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Novo abastecimento'),
        tooltip: 'Registrar abastecimento',
      ),
    );
  }
}

/// Wrap usado nos estados não-data (loading/error) para que a AppBar e
/// background permaneçam consistentes mesmo sem a lista.
class _ScaffoldedBody extends StatelessWidget {
  const _ScaffoldedBody({
    required this.vehicle,
    required this.appBarSealed,
    required this.filterState,
    required this.child,
  });

  final Vehicle vehicle;
  final bool appBarSealed;
  final FuelFilterState filterState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _AppBar(
          vehicle: vehicle,
          sealed: appBarSealed,
          filterState: filterState,
        ),
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }
}

/// Body principal com lista de entries. Separa lógica de scroll/header
/// do parent.
class _DataBody extends ConsumerWidget {
  const _DataBody({
    required this.vehicle,
    required this.allEntries,
    required this.filteredEntries,
    required this.scrollController,
    required this.appBarSealed,
    required this.filterState,
    this.visibleCount,
  });

  final Vehicle vehicle;

  /// Histórico completo (para cálculo de consumo — sagrado).
  final List<FuelEntry> allEntries;

  /// Histórico filtrado (para timeline).
  final List<FuelEntry> filteredEntries;

  final ScrollController scrollController;
  final bool appBarSealed;
  final FuelFilterState filterState;

  /// Quando não-null, limita quantas entradas são renderizadas na timeline
  /// (lazy load). Null = sem limite (lista pequena, <=25 entradas).
  final int? visibleCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Para consumo usamos sempre o histórico completo (cálculo é sagrado).
    final rows = computeForDisplay(allEntries);
    final hero = pickHeroKmPerLiter(rows);
    final monthStats = computeCurrentMonthStats(allEntries);

    final heroLabel = hero == null ? 'aguardando baseline' : 'último consumo';

    // Construímos a "lista" como uma sequência mista de headers de mês e
    // cards, achatada em itens — mais simples que SliverList intercalado
    // e suficiente para o volume típico (poucas dezenas de abastecimentos).
    //
    // Paginação lazy: exibimos apenas as primeiras [visibleCount] entradas
    // do histórico filtrado quando a lista é grande (>25 entradas). O cálculo
    // de consumo sempre usa o histórico completo — apenas a renderização é
    // limitada.
    //
    // A timeline usa os filteredEntries; computeForDisplay usa allEntries para
    // preservar a regra de consumo sagrado.
    final filteredRows = _buildFilteredRows(filteredEntries, rows);
    final allItems = _buildTimelineItems(filteredRows);
    final items = visibleCount != null && visibleCount! < allItems.length
        ? _limitItems(allItems, visibleCount!)
        : allItems;
    final hasMore = visibleCount != null && visibleCount! < allItems.length;

    // Centraliza um widget em ResponsiveWidths.content (720). Hero e AppBar
    // ficam fora — continuam full-width. Conteúdo abaixo do hero é limitado.
    Widget center(Widget child) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ResponsiveWidths.content),
        child: child,
      ),
    );

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        _AppBar(
          vehicle: vehicle,
          sealed: appBarSealed,
          filterState: filterState,
        ),
        SliverToBoxAdapter(
          child: VehicleHeroHeader(
            vehicle: vehicle,
            heroKmPerLiter: hero,
            heroLabel: heroLabel,
            monthSpend: monthStats.totalSpend,
            monthCount: monthStats.entryCount,
            monthLabel: monthStats.label,
          ),
        ),
        // Gráfico FIPE — só aparece se o veículo tem código FIPE configurado.
        if (vehicle.fipeCode != null)
          SliverToBoxAdapter(
            child: center(FipeHistoryChart(vehicleId: vehicle.id)),
          ),
        // Cards de custo por km e tendência — só se há ao menos 1 entry no
        // histórico completo (não dependem do filtro).
        if (allEntries.isNotEmpty) ...[
          SliverToBoxAdapter(child: center(CostPerKmCard(vehicle: vehicle))),
          SliverToBoxAdapter(child: center(TrendCard(vehicle: vehicle))),
          SliverToBoxAdapter(child: center(Co2InsightCard(vehicle: vehicle))),
          SliverToBoxAdapter(
            child: center(FavoriteStationCard(vehicle: vehicle)),
          ),
          // Card de viagens — acesso rápido ao modo viagem.
          SliverToBoxAdapter(
            child: center(_TripsBannerCard(vehicleId: vehicle.id)),
          ),
          // Calculadora etanol × gasolina — exclusiva pra veículos flex.
          if (vehicle.fuelType == FuelType.flex)
            SliverToBoxAdapter(
              child: center(_FuelEconomyBannerCard(vehicleId: vehicle.id)),
            ),
        ],
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: center(
              filterState.hasActiveFilters
                  ? _FilteredEmptyState(
                      onClear: () => ref
                          .read(fuelFilterStateProvider(vehicle.id).notifier)
                          .clear(),
                    )
                  : _EmptyState(
                      onAdd: () =>
                          context.push('/vehicles/${vehicle.id}/fuel/new'),
                    ),
            ),
          )
        else ...[
          SliverToBoxAdapter(child: center(const _HistoryHeader())),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              // Espaço pro FAB extended (maior quando há indicador de "mais").
              hasMore ? AppSpacing.xxl : AppSpacing.huge + AppSpacing.xl,
            ),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return center(switch (item) {
                  _MonthHeaderItem(:final label) => Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : AppSpacing.xl,
                      bottom: AppSpacing.sm + 2,
                      left: AppSpacing.xs,
                    ),
                    child: _MonthHeader(label: label),
                  ),
                  _EntryItem(:final row, :final showYear) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _DismissibleEntryCard(
                      row: row,
                      vehicleId: vehicle.id,
                      showYear: showYear,
                    ),
                  ),
                });
              },
            ),
          ),
          // Indicador de carregamento quando há mais entradas para mostrar.
          if (hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.huge + AppSpacing.xl,
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  /// Filtra [allComputedRows] para conter apenas as entries que estão em
  /// [filteredEntries], preservando os dados de consumo calculados.
  ///
  /// Necessário porque o consumo é calculado sobre o histórico completo, mas
  /// a timeline deve mostrar apenas as entries filtradas.
  static List<ConsumptionRow> _buildFilteredRows(
    List<FuelEntry> filteredEntries,
    List<ConsumptionRow> allComputedRows,
  ) {
    if (filteredEntries.isEmpty) return const [];
    final filteredIds = {for (final e in filteredEntries) e.id};
    return allComputedRows
        .where((row) => filteredIds.contains(row.entry.id))
        .toList();
  }

  /// Achata [rows] em uma sequência alternada de [_MonthHeaderItem] e
  /// [_EntryItem]. Como o histórico do veículo pode atravessar anos,
  /// o header inclui o ano por padrão; entries fora do ano corrente
  /// recebem showYear=true no eyebrow para evitar ambiguidade.
  List<_TimelineItem> _buildTimelineItems(List<ConsumptionRow> rows) {
    if (rows.isEmpty) return const [];
    final currentYear = DateTime.now().year;
    final items = <_TimelineItem>[];
    int? lastBucketKey;

    for (final row in rows) {
      final date = row.entry.date;
      final bucketKey = date.year * 100 + date.month;
      if (bucketKey != lastBucketKey) {
        final monthLabel = _formatMonthHeader(date);
        items.add(_MonthHeaderItem(label: monthLabel));
        lastBucketKey = bucketKey;
      }
      items.add(_EntryItem(row: row, showYear: date.year != currentYear));
    }

    return items;
  }

  static String _formatMonthHeader(DateTime date) {
    // "Maio 2026" — Capitalized, no upper-case shouting (o eyebrow do
    // hero usa uppercase; aqui é título de seção, mais quente).
    final raw = DateFormat('MMMM yyyy', 'pt_BR').format(date);
    if (raw.isEmpty) return raw;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  /// Limita [allItems] a [count] entradas (_EntryItem), preservando todos os
  /// headers de mês correspondentes. Garante que o corte não separe um header
  /// do seu primeiro card.
  static List<_TimelineItem> _limitItems(
    List<_TimelineItem> allItems,
    int count,
  ) {
    var entryCount = 0;
    final result = <_TimelineItem>[];
    for (final item in allItems) {
      result.add(item);
      if (item is _EntryItem) {
        entryCount++;
        if (entryCount >= count) break;
      }
    }
    return result;
  }
}

// ============================================================================
// Skeleton loading state da timeline
// ============================================================================

class _FuelHistorySkeleton extends StatelessWidget {
  const _FuelHistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imita o "HISTÓRICO / Abastecimentos" header
          SkeletonLine(width: 80, height: 11),
          SizedBox(height: AppSpacing.sm),
          SkeletonLine(width: 200, height: 24),
          SizedBox(height: AppSpacing.xxl),
          // Month header
          SkeletonLine(width: 100, height: 15),
          SizedBox(height: AppSpacing.md),
          // Cards
          SkeletonFuelCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonFuelCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonFuelCard(),
          SizedBox(height: AppSpacing.xxl),
          SkeletonLine(width: 80, height: 15),
          SizedBox(height: AppSpacing.md),
          SkeletonFuelCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonFuelCard(),
        ],
      ),
    );
  }
}

// ============================================================================
// AppBar
// ============================================================================

class _AppBar extends ConsumerWidget {
  const _AppBar({
    required this.vehicle,
    required this.sealed,
    required this.filterState,
  });

  final Vehicle vehicle;
  final bool sealed;
  final FuelFilterState filterState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Quando NÃO selada, o app bar fica sobre o painel brand: ícones
    // claros e título oculto. Quando selada (após scroll), vira AppBar
    // canônica com fundo surface + título.
    final foreground = sealed ? context.ink : AppColors.brandInk;

    // Status bar: branca (ícones claros) sobre o hero brand; escura (ícones
    // escuros) quando a AppBar selou e o fundo virou surface off-white.
    final overlayStyle = sealed
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          )
        : const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          );

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: sealed ? context.surface : AppColors.brand,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: overlayStyle,
      iconTheme: IconThemeData(color: foreground),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: foreground,
        tooltip: 'Voltar',
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/vehicles');
          }
        },
      ),
      title: AnimatedOpacity(
        duration: AppMotion.standard,
        opacity: sealed ? 1 : 0,
        child: Text(
          vehicle.nickname,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: context.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        // Filtro fica inline (contextual a esta lista, com badge de count).
        _FilterButton(
          vehicle: vehicle,
          filterState: filterState,
          foreground: foreground,
        ),
        // Demais navegações (lembretes, despesas, relatórios, insights,
        // compartilhar, editar) ficam num overflow "Mais" — antes eram 6
        // ícones lado a lado sem rótulo (fidelidade UX 19/06 — M2).
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: foreground),
          tooltip: 'Mais',
          onSelected: (value) {
            switch (value) {
              case 'reports':
                context.push('/vehicles/${vehicle.id}/reports');
              case 'expenses':
                context.push('/vehicles/${vehicle.id}/expenses');
              case 'reminders':
                context.push('/vehicles/${vehicle.id}/reminders');
              case 'insights':
                context.push('/vehicles/${vehicle.id}/insights');
              case 'share':
                context.push('/vehicles/${vehicle.id}/share');
              case 'edit':
                context.push('/vehicles/${vehicle.id}/edit');
            }
          },
          itemBuilder: (context) {
            // Em desktop (≥1024px) o rail já expõe Despesas/Lembretes/
            // Relatórios no bloco contextual do veículo. Escondemos do menu
            // pra evitar duplicidade.
            final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
            return [
              if (!isDesktop) ...[
                const PopupMenuItem(
                  value: 'reports',
                  child: ListTile(
                    leading: Icon(Icons.bar_chart),
                    title: Text('Relatórios'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'expenses',
                  child: ListTile(
                    leading: Icon(Icons.attach_money),
                    title: Text('Despesas'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'reminders',
                  child: ListTile(
                    leading: Icon(Icons.notifications_outlined),
                    title: Text('Lembretes'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              const PopupMenuItem(
                value: 'insights',
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_outlined),
                  title: Text('Insights'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Compartilhar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar veículo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ];
          },
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

// ============================================================================
// Botão de filtro com badge de contagem
// ============================================================================

class _FilterButton extends ConsumerWidget {
  const _FilterButton({
    required this.vehicle,
    required this.filterState,
    required this.foreground,
  });

  final Vehicle vehicle;
  final FuelFilterState filterState;
  final Color foreground;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = filterState.activeCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.tune_rounded),
          color: foreground,
          tooltip: 'Filtros',
          onPressed: () => _openFilterSheet(context, ref),
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.accentInk,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _FilterSheet(vehicleId: vehicle.id, initialState: filterState),
    );
  }
}

// ============================================================================
// Seção: histórico
// ============================================================================

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg + AppSpacing.xs,
        AppSpacing.xxl,
        AppSpacing.lg + AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HISTÓRICO',
            style: textTheme.labelSmall?.copyWith(
              color: context.inkMuted,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Abastecimentos',
            style: AppTypography.display(
              26,
              weight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.display(
        15,
        weight: FontWeight.w600,
        height: 1.1,
        color: context.inkMuted,
      ),
    );
  }
}

// ============================================================================
// Empty / error states
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // SingleChildScrollView evita overflow quando SliverFillRemaining dá
    // altura insuficiente pra ícone + título + corpo (regressão 28/05/2026:
    // 14px overflow em alguns devices).
    // SliverFillRemaining(hasScrollBody:false) dá altura fixa — Padding aqui
    // reduz a área útil, fazendo o Center subir o conteúdo acima do FAB
    // extended (≈80px + 16px margem) que mora no Scaffold.
    // SliverFillRemaining(hasScrollBody:false) entrega altura travada igual
    // à viewport restante. Em janela desktop "baixa" o Column + paddings
    // estouravam 47px (W2 — Web Sprint 8). SingleChildScrollView absorve
    // o overflow vertical sem mudar o layout em mobile.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const DashedFrame(icon: Icons.local_gas_station_outlined),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Nenhum abastecimento aqui ainda.',
                  style: AppTypography.display(
                    22,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Toque em "Novo abastecimento" pra começar a história deste carro.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: context.inkMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Não foi possível carregar os abastecimentos.',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state quando há filtros ativos mas nenhuma entry satisfaz.
class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.surfaceSunken,
                    borderRadius: AppRadius.allLg,
                  ),
                  child: Icon(
                    Icons.filter_list_off,
                    size: 30,
                    color: context.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Nenhum abastecimento com esses filtros.',
                  style: AppTypography.display(
                    22,
                    weight: FontWeight.w700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tente ampliar o período ou remover alguns critérios.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.inkMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Limpar filtros'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Items da timeline
// ============================================================================

sealed class _TimelineItem {
  const _TimelineItem();
}

class _MonthHeaderItem extends _TimelineItem {
  const _MonthHeaderItem({required this.label});
  final String label;
}

class _EntryItem extends _TimelineItem {
  const _EntryItem({required this.row, required this.showYear});
  final ConsumptionRow row;
  final bool showYear;
}

// ============================================================================
// Card embalado em Dismissible (swipe-to-delete + snackbar friendly)
// ============================================================================

class _DismissibleEntryCard extends ConsumerWidget {
  const _DismissibleEntryCard({
    required this.row,
    required this.vehicleId,
    required this.showYear,
  });

  final ConsumptionRow row;
  final String vehicleId;
  final bool showYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = row.entry;
    return Dismissible(
      key: ValueKey('fuel-entry-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: const _DismissBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await ref.read(fuelEntrySaverProvider).delete(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Abastecimento de ${formatDateBr(entry.date)} excluído.',
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(AppSpacing.lg),
              ),
            );
        }
      },
      child: FuelEntryCard(
        row: row,
        showYear: showYear,
        onTap: () => context.push('/vehicles/$vehicleId/fuel/${entry.id}/edit'),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir abastecimento?'),
        content: Text(
          'O abastecimento de ${formatDateBr(row.entry.date)} será removido. '
          'Você pode recuperar depois nas configurações.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.brandInk,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: AppRadius.allMd,
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: AppColors.danger),
          SizedBox(width: AppSpacing.sm),
          Text(
            'Excluir',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Banner: Viagens
// ============================================================================

class _TripsBannerCard extends StatelessWidget {
  const _TripsBannerCard({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: () => context.push('/vehicles/$vehicleId/trips'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.surfaceRaised,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: context.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.surfaceSunken,
                    borderRadius: AppRadius.allSm,
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    color: context.inkMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Viagens',
                        style: AppTypography.body(15, weight: FontWeight.w600),
                      ),
                      Text(
                        'Agrupe abastecimentos e despesas por período',
                        style: AppTypography.body(13, color: context.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.inkMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Banner: Etanol × Gasolina (exclusivo para veículos flex)
// ============================================================================

class _FuelEconomyBannerCard extends StatelessWidget {
  const _FuelEconomyBannerCard({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: () => context.push('/vehicles/$vehicleId/fuel-economy'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.surfaceRaised,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: context.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.surfaceSunken,
                    borderRadius: AppRadius.allSm,
                  ),
                  child: Icon(
                    Icons.calculate_outlined,
                    color: context.inkMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Etanol × Gasolina',
                        style: AppTypography.body(15, weight: FontWeight.w600),
                      ),
                      Text(
                        'Descubra qual combustível compensa hoje',
                        style: AppTypography.body(13, color: context.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.inkMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Bottom Sheet: Filtros
// ============================================================================

/// Bottom sheet de filtros do histórico de abastecimentos.
///
/// Trabalha com estado local até o usuário apertar "Aplicar" — garante que
/// mudanças parciais não afetem a lista antes de confirmação.
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.vehicleId, required this.initialState});

  final String vehicleId;
  final FuelFilterState initialState;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late FuelFilterState _draft;
  late final TextEditingController _searchController;

  // Debounce para o campo de busca
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialState;
    _searchController = TextEditingController(
      text: widget.initialState.textQuery ?? '',
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(
          () =>
              _draft = _draft.copyWith(textQuery: value.isEmpty ? null : value),
        );
      }
    });
  }

  void _apply() {
    ref.read(fuelFilterStateProvider(widget.vehicleId).notifier).apply(_draft);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _draft = FuelFilterState();
      _searchController.clear();
    });
  }

  Future<void> _pickCustomPeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: _draft.period != null
          ? DateTimeRange(start: _draft.period!.start, end: _draft.period!.end)
          : null,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione o período',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      saveText: 'Salvar',
    );
    if (picked != null && mounted) {
      setState(() => _draft = _draft.copyWith(period: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.hairline,
                    borderRadius: AppRadius.allSm,
                  ),
                ),
              ),
            ),
            // Título + botão limpar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Filtros',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (_draft.hasActiveFilters)
                    TextButton(
                      onPressed: _clear,
                      child: const Text('Limpar tudo'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Busca livre ---
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Buscar por posto ou combustível…',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: context.surfaceSunken,
                        border: const OutlineInputBorder(
                          borderRadius: AppRadius.allSm,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // --- Tipo de combustível ---
                    Text(
                      'Tipo de combustível',
                      style: textTheme.labelLarge?.copyWith(
                        color: context.inkMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _FuelTypeChip(
                          label: 'Gasolina',
                          value: 'gasolina',
                          selected: _draft.fuelType == 'gasolina',
                          onSelected: (v) => setState(
                            () => _draft = _draft.copyWith(
                              fuelType: v ? 'gasolina' : null,
                            ),
                          ),
                        ),
                        _FuelTypeChip(
                          label: 'Etanol',
                          value: 'etanol',
                          selected: _draft.fuelType == 'etanol',
                          onSelected: (v) => setState(
                            () => _draft = _draft.copyWith(
                              fuelType: v ? 'etanol' : null,
                            ),
                          ),
                        ),
                        _FuelTypeChip(
                          label: 'Diesel',
                          value: 'diesel',
                          selected: _draft.fuelType == 'diesel',
                          onSelected: (v) => setState(
                            () => _draft = _draft.copyWith(
                              fuelType: v ? 'diesel' : null,
                            ),
                          ),
                        ),
                        _FuelTypeChip(
                          label: 'GNV',
                          value: 'gnv',
                          selected: _draft.fuelType == 'gnv',
                          onSelected: (v) => setState(
                            () => _draft = _draft.copyWith(
                              fuelType: v ? 'gnv' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // --- Período ---
                    Text(
                      'Período',
                      style: textTheme.labelLarge?.copyWith(
                        color: context.inkMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _PeriodPresetChip(
                          label: 'Últimos 30 dias',
                          isActive: _isLast30Days(),
                          onTap: () {
                            final now = DateTime.now();
                            setState(
                              () => _draft = _draft.copyWith(
                                period: DateTimeRange(
                                  start: now.subtract(const Duration(days: 30)),
                                  end: now,
                                ),
                              ),
                            );
                          },
                        ),
                        _PeriodPresetChip(
                          label: 'Este mês',
                          isActive: _isCurrentMonth(),
                          onTap: () {
                            final now = DateTime.now();
                            setState(
                              () => _draft = _draft.copyWith(
                                period: DateTimeRange(
                                  start: DateTime(now.year, now.month, 1),
                                  end: now,
                                ),
                              ),
                            );
                          },
                        ),
                        _PeriodPresetChip(
                          label: _customPeriodLabel(),
                          isActive:
                              _draft.period != null &&
                              !_isLast30Days() &&
                              !_isCurrentMonth(),
                          onTap: _pickCustomPeriod,
                        ),
                        if (_draft.period != null)
                          ActionChip(
                            label: const Text('Limpar período'),
                            avatar: const Icon(Icons.close, size: 16),
                            onPressed: () => setState(
                              () => _draft = _draft.copyWith(period: null),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // --- Tanque cheio ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Só tanque cheio', style: textTheme.bodyLarge),
                        Switch.adaptive(
                          value: _draft.onlyFullTank,
                          onChanged: (v) => setState(
                            () => _draft = _draft.copyWith(onlyFullTank: v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // --- Ordenação ---
                    Text(
                      'Ordenar por',
                      style: textTheme.labelLarge?.copyWith(
                        color: context.inkMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<FuelSortBy>(
                      key: ValueKey(_draft.sortBy),
                      initialValue: _draft.sortBy,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: context.surfaceSunken,
                        border: const OutlineInputBorder(
                          borderRadius: AppRadius.allSm,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      items: FuelSortBy.values
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _draft = _draft.copyWith(sortBy: v));
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
            // Botão "Aplicar"
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: FilledButton(
                onPressed: _apply,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.brandInk,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLast30Days() {
    if (_draft.period == null) return false;
    final now = DateTime.now();
    final expected30 = now.subtract(const Duration(days: 30));
    final start = _draft.period!.start;
    return start.year == expected30.year &&
        start.month == expected30.month &&
        start.day == expected30.day;
  }

  bool _isCurrentMonth() {
    if (_draft.period == null) return false;
    final now = DateTime.now();
    final start = _draft.period!.start;
    return start.year == now.year && start.month == now.month && start.day == 1;
  }

  String _customPeriodLabel() {
    if (_draft.period != null && !_isLast30Days() && !_isCurrentMonth()) {
      final fmt = DateFormat('dd/MM/yy');
      return '${fmt.format(_draft.period!.start)} – ${fmt.format(_draft.period!.end)}';
    }
    return 'Personalizado';
  }
}

// ============================================================================
// Chips auxiliares do FilterSheet
// ============================================================================

class _FuelTypeChip extends StatelessWidget {
  const _FuelTypeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.brand,
      checkmarkColor: AppColors.brandInk,
      labelStyle: TextStyle(
        color: selected ? AppColors.brandInk : context.ink,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: selected ? AppColors.brand : context.hairline),
      backgroundColor: context.surfaceSunken,
    );
  }
}

class _PeriodPresetChip extends StatelessWidget {
  const _PeriodPresetChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.brand,
      checkmarkColor: AppColors.brandInk,
      labelStyle: TextStyle(
        color: isActive ? AppColors.brandInk : context.ink,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: isActive ? AppColors.brand : context.hairline),
      backgroundColor: context.surfaceSunken,
    );
  }
}
