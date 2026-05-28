import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/favorite_station_analyzer.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/fuel/station_aggregation.dart';
import 'package:autolog/features/fuel/station_brands.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Card "Seu posto preferido" para o detalhe do veículo.
///
/// Recebe [vehicle] e lê os fuel entries via [fuelEntriesByVehicleProvider].
/// Computa [analyzeFavoriteStation] e renderiza o insight.
class FavoriteStationCard extends ConsumerWidget {
  const FavoriteStationCard({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));

    return entriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        final insight = analyzeFavoriteStation(entries);
        return _FavoriteStationContent(insight: insight);
      },
    );
  }
}

class _FavoriteStationContent extends StatelessWidget {
  const _FavoriteStationContent({required this.insight});

  final FavoriteStationInsight insight;

  @override
  Widget build(BuildContext context) {
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
          child: insight.favorite == null
              ? _buildEmpty(context)
              : _buildData(context, insight),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Eyebrow('SEU POSTO PREFERIDO'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Adicione bandeira e nome ao registrar abastecimento pra ver seu posto preferido.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: context.inkMuted),
        ),
      ],
    );
  }

  Widget _buildData(BuildContext context, FavoriteStationInsight insight) {
    final favorite = insight.favorite!;
    final cheapest = insight.cheapestQualified;

    final currFmt = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );

    final avgFormatted = currFmt.format(
      double.parse(favorite.avgPricePerLiter.toString()),
    );
    final titleText = '${favorite.brand ?? '—'} • ${favorite.name ?? 'Posto'}';
    final subText =
        '${favorite.entriesCount} abastecimento${favorite.entriesCount == 1 ? '' : 's'} • $avgFormatted/L em média';

    // Determina se cheapest é diferente do favorite.
    // Promove cheapest para non-nullable para uso seguro no widget filho.
    final cheapestStation =
        cheapest != null && !_isSameStation(favorite, cheapest)
        ? cheapest
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Eyebrow('SEU POSTO PREFERIDO'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          titleText,
          style: AppTypography.display(
            22,
            weight: FontWeight.w700,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(subText, style: AppTypography.body(13, color: context.inkMuted)),
        if (cheapestStation != null) ...[
          const SizedBox(height: AppSpacing.md),
          _CheapestHintBadge(cheapest: cheapestStation, currFmt: currFmt),
        ],
      ],
    );
  }

  /// Verifica se dois StationStats representam a mesma estação usando
  /// [normalizeStation] (mesma lógica do aggregator).
  bool _isSameStation(StationStats a, StationStats b) {
    final normBrandA = a.brand != null ? normalizeStation(a.brand!) : '';
    final normNameA = a.name != null ? normalizeStation(a.name!) : '';
    final normBrandB = b.brand != null ? normalizeStation(b.brand!) : '';
    final normNameB = b.name != null ? normalizeStation(b.name!) : '';

    return normBrandA == normBrandB && normNameA == normNameB;
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

class _CheapestHintBadge extends StatelessWidget {
  const _CheapestHintBadge({required this.cheapest, required this.currFmt});

  final StationStats cheapest;
  final NumberFormat currFmt;

  @override
  Widget build(BuildContext context) {
    final avgFormatted = currFmt.format(
      double.parse(cheapest.avgPricePerLiter.toString()),
    );
    final label = '💡 Mais barato: ${cheapest.brand ?? '—'} • $avgFormatted/L';

    return DecoratedBox(
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
          label,
          style: AppTypography.body(
            12,
            weight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }
}
