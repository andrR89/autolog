import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/skeleton.dart';
import 'package:autolog/data/repositories/trip_repository.dart';
import 'package:autolog/domain/models/trip.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Provider reativo para a lista de viagens de um veículo.
final tripsByVehicleProvider = StreamProvider.family<List<Trip>, String>((
  ref,
  vehicleId,
) {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.watchByVehicle(vehicleId);
});

/// Tela de lista de viagens. Entry point: `/vehicles/:vehicleId/trips`.
class TripsListScreen extends ConsumerWidget {
  const TripsListScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsByVehicleProvider(vehicle.id));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.brand,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        iconTheme: const IconThemeData(color: AppColors.brandInk),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.brandInk,
          tooltip: 'Voltar',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vehicles/${vehicle.id}');
            }
          },
        ),
        title: Text(
          'Viagens',
          style: AppTypography.body(
            17,
            weight: FontWeight.w600,
            color: AppColors.brandInk,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/${vehicle.id}/trips/new'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nova viagem'),
        tooltip: 'Registrar viagem',
      ),
      body: tripsAsync.when(
        loading: () => const _TripsSkeleton(),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(tripsByVehicleProvider(vehicle.id)),
        ),
        data: (trips) => trips.isEmpty
            ? _EmptyState(
                onAdd: () => context.push('/vehicles/${vehicle.id}/trips/new'),
              )
            : _TripsList(vehicle: vehicle, trips: trips),
      ),
    );
  }
}

// ============================================================================
// Lista
// ============================================================================

class _TripsList extends StatelessWidget {
  const _TripsList({required this.vehicle, required this.trips});

  final Vehicle vehicle;
  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge + AppSpacing.xl,
      ),
      itemCount: trips.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _TripCard(
          trip: trip,
          onTap: () => context.push('/vehicles/${vehicle.id}/trips/${trip.id}'),
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    final dateRange =
        '${dateFmt.format(trip.startDate)} – ${dateFmt.format(trip.endDate)}';

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allMd,
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
                width: 44,
                height: 44,
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
                      trip.name,
                      style: AppTypography.body(15, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateRange,
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
    );
  }
}

// ============================================================================
// Skeleton de carregamento da lista de viagens
// ============================================================================

class _TripsSkeleton extends StatelessWidget {
  const _TripsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      child: Column(
        children: [
          SkeletonListCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonListCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonListCard(),
        ],
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
    return Center(
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
                  Icons.map_outlined,
                  size: 30,
                  color: context.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Nenhuma viagem registrada.',
                style: AppTypography.display(
                  22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Crie uma viagem para agrupar abastecimentos e despesas de um período.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: context.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nova viagem'),
              ),
            ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: context.inkMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Não foi possível carregar as viagens.',
              style: Theme.of(context).textTheme.titleMedium,
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
