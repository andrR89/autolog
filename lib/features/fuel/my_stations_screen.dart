import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/features/fuel/favorite_station_analyzer.dart';
import 'package:autolog/features/fuel/station_aggregation.dart';
import 'package:autolog/features/fuel/station_brands.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Provider — agrega entries de todos os veículos do user
// ---------------------------------------------------------------------------

/// Carrega todos os abastecimentos de todos os veículos do usuário e aplica
/// [aggregateByStation]. Retorna a lista de [StationStats] ordenada.
final allStationStatsProvider =
    FutureProvider.autoDispose<List<StationStats>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final vehicleRepo = ref.watch(vehicleRepositoryProvider);
  final fuelRepo = ref.watch(fuelEntryRepositoryProvider);

  final vehicles = await vehicleRepo.listByUser(userId);
  final allEntries = <FuelEntry>[];

  for (final v in vehicles) {
    final entries = await fuelRepo.listByVehicle(v.id);
    allEntries.addAll(entries);
  }

  return aggregateByStation(allEntries);
});

/// Carrega todos os abastecimentos de todos os veículos do usuário e calcula
/// o [FavoriteStationInsight] agregado (todos os carros juntos).
final allStationInsightProvider =
    FutureProvider.autoDispose<FavoriteStationInsight>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final vehicleRepo = ref.watch(vehicleRepositoryProvider);
  final fuelRepo = ref.watch(fuelEntryRepositoryProvider);

  final vehicles = await vehicleRepo.listByUser(userId);
  final allEntries = <FuelEntry>[];

  for (final v in vehicles) {
    final entries = await fuelRepo.listByVehicle(v.id);
    allEntries.addAll(entries);
  }

  return analyzeFavoriteStation(allEntries);
});

// ---------------------------------------------------------------------------
// Tela "Meus postos"
// ---------------------------------------------------------------------------

/// Tela que exibe a agregação histórica de abastecimentos por posto/bandeira.
class MyStationsScreen extends ConsumerWidget {
  const MyStationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(allStationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.hairline,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: const Text('Meus postos'),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              'Erro ao carregar postos.\n$err',
              textAlign: TextAlign.center,
              style: AppTypography.body(14, color: AppColors.danger),
            ),
          ),
        ),
        data: (stats) {
          if (stats.isEmpty) {
            return _EmptyState();
          }
          return _StationsList(stats: stats);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets internos
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Lista de postos com seção de posto preferido no topo
// ---------------------------------------------------------------------------

class _StationsList extends ConsumerWidget {
  const _StationsList({required this.stats});

  final List<StationStats> stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightAsync = ref.watch(allStationInsightProvider);

    return insightAsync.when(
      loading: () => _buildList(context, stats, null),
      error: (_, _) => _buildList(context, stats, null),
      data: (insight) => _buildList(context, stats, insight),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<StationStats> stats,
    FavoriteStationInsight? insight,
  ) {
    final showInsight = insight != null &&
        (insight.favorite != null || insight.cheapestQualified != null);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      itemCount: stats.length + (showInsight ? 1 : 0),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        if (showInsight && i == 0) {
          return _FavoriteInsightSection(insight: insight);
        }
        final statIndex = showInsight ? i - 1 : i;
        return _StationCard(stat: stats[statIndex]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Seção "Posto preferido" no topo da lista de postos
// ---------------------------------------------------------------------------

class _FavoriteInsightSection extends StatelessWidget {
  const _FavoriteInsightSection({required this.insight});

  final FavoriteStationInsight insight;

  @override
  Widget build(BuildContext context) {
    final favorite = insight.favorite;
    final cheapest = insight.cheapestQualified;

    final currFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.sm,
            left: AppSpacing.xs,
          ),
          child: Text(
            'POSTO PREFERIDO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 1.4,
                ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (favorite != null) ...[
                  Text(
                    '${favorite.brand ?? '—'} • ${favorite.name ?? 'Posto'}',
                    style: AppTypography.display(
                      22,
                      weight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${favorite.entriesCount} abastecimento${favorite.entriesCount == 1 ? '' : 's'} '
                    '• ${currFmt.format(double.parse(favorite.avgPricePerLiter.toString()))}/L em média',
                    style: AppTypography.body(13, color: AppColors.inkMuted),
                  ),
                ],
                if (cheapest != null &&
                    !_isSameStation(favorite, cheapest)) ...[
                  const SizedBox(height: AppSpacing.md),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: AppRadius.allSm,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        '💡 Mais barato: ${cheapest.brand ?? '—'} • '
                        '${currFmt.format(double.parse(cheapest.avgPricePerLiter.toString()))}/L',
                        style: AppTypography.body(
                          12,
                          weight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.sm,
            left: AppSpacing.xs,
          ),
          child: Text(
            'TODOS OS POSTOS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 1.4,
                ),
          ),
        ),
      ],
    );
  }

  bool _isSameStation(StationStats? a, StationStats b) {
    if (a == null) return false;
    final normBrandA = a.brand != null ? normalizeStation(a.brand!) : '';
    final normNameA = a.name != null ? normalizeStation(a.name!) : '';
    final normBrandB = b.brand != null ? normalizeStation(b.brand!) : '';
    final normNameB = b.name != null ? normalizeStation(b.name!) : '';
    return normBrandA == normBrandB && normNameA == normNameB;
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
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_gas_station_outlined,
              size: 56,
              color: AppColors.inkSoft,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhum posto identificado ainda.',
              style: AppTypography.body(
                16,
                weight: FontWeight.w600,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Adicione bandeira/nome ao registrar abastecimento.',
              style: AppTypography.body(14, color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.stat});

  final StationStats stat;

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );
    final dateFmt = DateFormat('dd/MM/yy');

    final titleText =
        '${stat.brand ?? "—"} • ${stat.name ?? "Posto"}';
    final avgFormatted = currencyFmt.format(
      double.parse(stat.avgPricePerLiter.toString()),
    );
    final subtitleText =
        '${stat.entriesCount} abastecimento${stat.entriesCount == 1 ? '' : 's'} • $avgFormatted/L médio';
    final totalFormatted = currencyFmt.format(
      double.parse(stat.totalSpent.toString()),
    );
    final dateFormatted = dateFmt.format(stat.lastEntryDate.toLocal());

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: AppRadius.allSm,
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.local_gas_station_outlined,
                  size: 20,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Título + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: AppTypography.body(
                      15,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitleText,
                    style: AppTypography.body(13, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Trailing: total + data
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  totalFormatted,
                  style: AppTypography.body(
                    14,
                    weight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  dateFormatted,
                  style: AppTypography.body(12, color: AppColors.inkSoft),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
