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

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/skeleton.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/domain/services/consumption_calculator.dart';
import 'package:autolog/features/fuel/fuel_entry_saver.dart';
import 'package:autolog/features/fuel/fuel_history_helpers.dart';
import 'package:autolog/features/fuel/widgets/favorite_station_card.dart';
import 'package:autolog/features/fuel/widgets/fuel_entry_card.dart';
import 'package:autolog/features/fuel/widgets/vehicle_hero_header.dart';
import 'package:autolog/features/reports/widgets/co2_card.dart';
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
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (_scrollController.offset >= maxScroll - 200) {
        final entriesAsync = ref.read(
          fuelEntriesByVehicleProvider(widget.vehicle.id),
        );
        final totalEntries = entriesAsync.value?.length ?? 0;
        if (_visibleCount < totalEntries) {
          setState(() => _visibleCount += _kPageSize);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    final entriesAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));

    // Reseta paginação se a lista mudou de tamanho.
    entriesAsync.whenData((entries) {
      if (entries.length < _visibleCount) {
        _visibleCount = _kPageSize;
      }
    });

    return Scaffold(
      body: entriesAsync.when(
        loading: () => _ScaffoldedBody(
          vehicle: vehicle,
          appBarSealed: _appBarSealed,
          child: const _FuelHistorySkeleton(),
        ),
        error: (_, _) => _ScaffoldedBody(
          vehicle: vehicle,
          appBarSealed: _appBarSealed,
          child: _ErrorState(
            onRetry: () =>
                ref.invalidate(fuelEntriesByVehicleProvider(vehicle.id)),
          ),
        ),
        data: (entries) => _DataBody(
          vehicle: vehicle,
          entries: entries,
          scrollController: _scrollController,
          appBarSealed: _appBarSealed,
          visibleCount: entries.length <= _kPageSize ? null : _visibleCount,
        ),
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
    required this.child,
  });

  final Vehicle vehicle;
  final bool appBarSealed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _AppBar(vehicle: vehicle, sealed: appBarSealed),
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
    required this.entries,
    required this.scrollController,
    required this.appBarSealed,
    this.visibleCount,
  });

  final Vehicle vehicle;
  final List<FuelEntry> entries;
  final ScrollController scrollController;
  final bool appBarSealed;

  /// Quando não-null, limita quantas entradas são renderizadas na timeline
  /// (lazy load). Null = sem limite (lista pequena, <=25 entradas).
  final int? visibleCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Para consumo usamos sempre o histórico completo (cálculo é sagrado).
    final rows = computeForDisplay(entries);
    final hero = pickHeroKmPerLiter(rows);
    final monthStats = computeCurrentMonthStats(entries);

    final heroLabel = hero == null ? 'aguardando baseline' : 'último consumo';

    // Construímos a "lista" como uma sequência mista de headers de mês e
    // cards, achatada em itens — mais simples que SliverList intercalado
    // e suficiente para o volume típico (poucas dezenas de abastecimentos).
    //
    // Paginação lazy: exibimos apenas as primeiras [visibleCount] entradas
    // do histórico quando a lista é grande (>25 entradas). O cálculo de
    // consumo sempre usa o histórico completo — apenas a renderização é
    // limitada.
    final allItems = _buildTimelineItems(rows);
    final items = visibleCount != null && visibleCount! < allItems.length
        ? _limitItems(allItems, visibleCount!)
        : allItems;
    final hasMore = visibleCount != null && visibleCount! < allItems.length;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        _AppBar(vehicle: vehicle, sealed: appBarSealed),
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
          SliverToBoxAdapter(child: FipeHistoryChart(vehicleId: vehicle.id)),
        // Cards de custo por km e tendência — só se há ao menos 1 entry.
        if (entries.isNotEmpty) ...[
          SliverToBoxAdapter(child: CostPerKmCard(vehicle: vehicle)),
          SliverToBoxAdapter(child: TrendCard(vehicle: vehicle)),
          SliverToBoxAdapter(child: Co2Card(vehicle: vehicle)),
          SliverToBoxAdapter(child: FavoriteStationCard(vehicle: vehicle)),
          // Card de viagens — acesso rápido ao modo viagem.
          SliverToBoxAdapter(child: _TripsBannerCard(vehicleId: vehicle.id)),
          // Calculadora etanol × gasolina — exclusiva pra veículos flex.
          if (vehicle.fuelType == FuelType.flex)
            SliverToBoxAdapter(
              child: _FuelEconomyBannerCard(vehicleId: vehicle.id),
            ),
        ],
        if (items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              onAdd: () => context.push('/vehicles/${vehicle.id}/fuel/new'),
            ),
          )
        else ...[
          const SliverToBoxAdapter(child: _HistoryHeader()),
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
                return switch (item) {
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
                };
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

class _AppBar extends StatelessWidget {
  const _AppBar({required this.vehicle, required this.sealed});

  final Vehicle vehicle;
  final bool sealed;

  @override
  Widget build(BuildContext context) {
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
        IconButton(
          icon: const Icon(Icons.auto_awesome_outlined),
          color: foreground,
          tooltip: 'Insights',
          onPressed: () => context.push('/vehicles/${vehicle.id}/insights'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: foreground,
          tooltip: 'Lembretes',
          onPressed: () => context.push('/vehicles/${vehicle.id}/reminders'),
        ),
        IconButton(
          icon: const Icon(Icons.attach_money),
          color: foreground,
          tooltip: 'Despesas',
          onPressed: () => context.push('/vehicles/${vehicle.id}/expenses'),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart),
          color: foreground,
          tooltip: 'Relatórios',
          onPressed: () => context.push('/vehicles/${vehicle.id}/reports'),
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          color: foreground,
          tooltip: 'Compartilhar',
          onPressed: () => context.push('/vehicles/${vehicle.id}/share'),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          color: foreground,
          tooltip: 'Editar veículo',
          onPressed: () => context.push('/vehicles/${vehicle.id}/edit'),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
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
                    Icons.local_gas_station_outlined,
                    size: 30,
                    color: context.inkMuted,
                  ),
                ),
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
                  'Toque em + pra começar a história deste carro.',
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
