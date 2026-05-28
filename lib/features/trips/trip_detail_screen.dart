import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/trip_repository.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/trip.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/expenses/expenses_list_screen.dart'
    show expensesByVehicleProvider;
import 'package:autolog/features/fuel/fuel_history_screen.dart'
    show fuelEntriesByVehicleProvider;
import 'package:autolog/features/trips/trip_stats.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Detalhe de uma viagem — stats + timeline fuel + despesas no range.
class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({
    super.key,
    required this.vehicle,
    required this.trip,
  });

  final Vehicle vehicle;
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelsAsync = ref.watch(fuelEntriesByVehicleProvider(vehicle.id));
    final expensesAsync = ref.watch(expensesByVehicleProvider(vehicle.id));

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
              context.go('/vehicles/${vehicle.id}/trips');
            }
          },
        ),
        title: Text(
          trip.name,
          style: AppTypography.body(
            17,
            weight: FontWeight.w600,
            color: AppColors.brandInk,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.brandInk,
            tooltip: 'Editar viagem',
            onPressed: () =>
                context.push('/vehicles/${vehicle.id}/trips/${trip.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.brandInk,
            tooltip: 'Excluir viagem',
            onPressed: () => _confirmDelete(context, ref),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      // FAB "+ Adicionar" abre sheet com 2 atalhos pra entry novo
      // (abastecimento ou despesa) com data dentro do range da viagem.
      // Decisão: navega pras rotas existentes; user escolhe data no form.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.brandInk,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
        onPressed: () => _showAddSheet(context, vehicle.id),
      ),
      body: fuelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Não foi possível carregar os dados.')),
        data: (fuels) => expensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Não foi possível carregar os dados.')),
          data: (expenses) =>
              _DetailBody(trip: trip, fuels: fuels, expenses: expenses),
        ),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, String vehicleId) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'ADICIONAR À VIAGEM',
                style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_gas_station_outlined),
              title: const Text('Abastecimento'),
              subtitle: Text(
                'Lembre de usar uma data dentro de '
                '${_fmt(trip.startDate)} a ${_fmt(trip.endDate)}.',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/vehicles/$vehicleId/fuel/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Despesa'),
              subtitle: Text(
                'Lembre de usar uma data dentro de '
                '${_fmt(trip.startDate)} a ${_fmt(trip.endDate)}.',
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/vehicles/$vehicleId/expenses/new');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir viagem?'),
        content: Text(
          'A viagem "${trip.name}" será removida. '
          'Os abastecimentos e despesas não são apagados.',
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

    if (confirmed == true && context.mounted) {
      await ref.read(tripRepositoryProvider).softDelete(trip.id);
      if (context.mounted) {
        context.go('/vehicles/${vehicle.id}/trips');
      }
    }
  }
}

// ============================================================================
// Body principal
// ============================================================================

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.trip,
    required this.fuels,
    required this.expenses,
  });

  final Trip trip;
  final List<FuelEntry> fuels;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final stats = computeTripStats(
      start: trip.startDate,
      end: trip.endDate,
      fuels: fuels,
      expenses: expenses,
    );

    // Timeline: fuel + expense combinados, ordenados por date.
    final timeline = _buildTimeline(fuels, expenses, trip);

    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    final dateRange =
        '${dateFmt.format(trip.startDate)} – ${dateFmt.format(trip.endDate)}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Text(
          trip.name,
          style: AppTypography.display(
            26,
            weight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: context.inkMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$dateRange · ${stats.days} ${stats.days == 1 ? 'dia' : 'dias'}',
              style: AppTypography.body(13, color: context.inkMuted),
            ),
          ],
        ),
        if (trip.notes != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            trip.notes!,
            style: AppTypography.body(14, color: context.inkMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),

        // ── Stats card ────────────────────────────────────────────────────────
        _StatsCard(stats: stats),
        const SizedBox(height: AppSpacing.xl),

        // ── Timeline ──────────────────────────────────────────────────────────
        if (timeline.isNotEmpty) ...[
          Text(
            'HISTÓRICO DA VIAGEM',
            style: AppTypography.body(
              12,
              weight: FontWeight.w700,
              color: context.inkMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...timeline.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _TimelineItem(item: item),
            ),
          ),
        ] else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Nenhum abastecimento ou despesa neste período.',
                style: AppTypography.body(14, color: context.inkMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  List<_TripTimelineEntry> _buildTimeline(
    List<FuelEntry> fuels,
    List<Expense> expenses,
    Trip trip,
  ) {
    final startDay = DateTime.utc(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final endDay = DateTime.utc(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );

    final items = <_TripTimelineEntry>[];

    for (final f in fuels) {
      final d = DateTime.utc(f.date.year, f.date.month, f.date.day);
      if (!d.isBefore(startDay) && !d.isAfter(endDay)) {
        items.add(_TripTimelineEntry.fuel(f));
      }
    }

    for (final x in expenses) {
      final d = DateTime.utc(x.date.year, x.date.month, x.date.day);
      if (!d.isBefore(startDay) && !d.isAfter(endDay)) {
        items.add(_TripTimelineEntry.expense(x));
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }
}

// ============================================================================
// Stats card
// ============================================================================

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final TripStats stats;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo da viagem',
              style: AppTypography.body(
                13,
                weight: FontWeight.w700,
                color: context.inkMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StatRow(
              icon: Icons.payments_outlined,
              label: 'Total gasto',
              value: currFmt.format(stats.totalSpent.toDouble()),
              highlight: true,
            ),
            const _Divider(),
            _StatRow(
              icon: Icons.local_gas_station_outlined,
              label: 'Combustível (${stats.fuelCount} abastecimentos)',
              value: currFmt.format(stats.fuelSpent.toDouble()),
            ),
            const _Divider(),
            _StatRow(
              icon: Icons.receipt_outlined,
              label: 'Despesas (${stats.expenseCount} lançamentos)',
              value: currFmt.format(stats.expensesSpent.toDouble()),
            ),
            const _Divider(),
            _StatRow(
              icon: Icons.speed_outlined,
              label: 'Quilômetros rodados',
              value: stats.kmDriven > 0 ? '${stats.kmDriven} km' : '—',
            ),
            const _Divider(),
            _StatRow(
              icon: Icons.eco_outlined,
              label: 'Consumo médio',
              value: stats.avgConsumptionKmL != null
                  ? '${_fmtDecimal(stats.avgConsumptionKmL!)} km/l'
                  : '—',
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDecimal(Decimal d) {
    // Remove trailing zeros for display.
    final s = d.toStringAsFixed(2);
    return s;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? AppColors.brand : context.inkMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body(
                14,
                color: highlight ? context.ink : context.inkMuted,
                weight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.body(
              14,
              weight: FontWeight.w700,
              color: highlight ? AppColors.brand : context.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: context.hairline, height: 1, thickness: 1);
  }
}

// ============================================================================
// Timeline
// ============================================================================

class _TripTimelineEntry {
  _TripTimelineEntry.fuel(this._fuel) : _expense = null;
  _TripTimelineEntry.expense(this._expense) : _fuel = null;

  final FuelEntry? _fuel;
  final Expense? _expense;

  DateTime get date => _fuel?.date ?? _expense!.date;

  bool get isFuel => _fuel != null;
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item});

  final _TripTimelineEntry item;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM', 'pt_BR');
    final currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

    if (item.isFuel) {
      final f = item._fuel!;
      return _ItemCard(
        icon: Icons.local_gas_station_outlined,
        iconColor: AppColors.brand,
        title: 'Abastecimento',
        subtitle: '${f.liters.toStringAsFixed(2)} l · ${f.odometer} km',
        trailing: currFmt.format(f.totalCost.toDouble()),
        date: dateFmt.format(f.date),
      );
    } else {
      final x = item._expense!;
      return _ItemCard(
        icon: Icons.receipt_outlined,
        iconColor: context.inkMuted,
        title: x.description,
        subtitle: x.category.wire,
        trailing: currFmt.format(x.amount.toDouble()),
        date: dateFmt.format(x.date),
      );
    }
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.date,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final String date;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.surfaceSunken,
                borderRadius: AppRadius.allSm,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body(14, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$subtitle · $date',
                    style: AppTypography.body(12, color: context.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              trailing,
              style: AppTypography.body(14, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
