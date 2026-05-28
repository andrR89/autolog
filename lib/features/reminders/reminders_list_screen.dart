// Tela de lista de lembretes — redesign editorial (Tranche C3).
//
// Design:
// - AppBar transparente que sela ao rolar.
// - Hero panel brand com contador de pendentes ("3 pendentes" / "Tudo em dia").
// - Lista em 2 seções visuais: PENDENTES (topo) e CONCLUÍDOS (base, mais discretos).
// - Cards com checkbox de toggle done, título bold/strikethrough, chip de tipo,
//   sub com ícone contextual (speedometer/calendar) e badge urgência.
// - Swipe endToStart para excluir.
// - FAB extended "Novo lembrete" em accent lima.
// - Empty state convidativo.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/reminders/reminder_saver.dart';
import 'package:autolog/features/reminders/widgets/reminder_card.dart';
import 'package:autolog/features/reminders/widgets/reminders_empty_state.dart';
import 'package:autolog/features/reminders/widgets/reminders_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provider reativo para a lista de lembretes de um veículo.
///
/// Emite a cada mudança no banco local (Drift watch).
final remindersByVehicleProvider =
    StreamProvider.family<List<Reminder>, String>((ref, vehicleId) {
      final repo = ref.watch(reminderRepositoryProvider);
      return repo.watchByVehicle(vehicleId);
    });

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

class RemindersListScreen extends ConsumerWidget {
  const RemindersListScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersByVehicleProvider(vehicle.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: AppColors.brand.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        // Status bar com ícones claros — AppBar fica sobre o hero brand escuro.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: Text(
          'Lembretes',
          style: AppTypography.body(
            17,
            weight: FontWeight.w600,
            color: AppColors.brandInk,
          ),
        ),
        foregroundColor: AppColors.brandInk,
        iconTheme: const IconThemeData(color: AppColors.brandInk),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(remindersByVehicleProvider(vehicle.id)),
        ),
        data: (reminders) => _Body(vehicle: vehicle, reminders: reminders),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/${vehicle.id}/reminders/new'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Novo lembrete'),
        tooltip: 'Adicionar lembrete',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  const _Body({required this.vehicle, required this.reminders});

  final Vehicle vehicle;
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = reminders.where((r) => !r.isDone).toList();
    final done = reminders.where((r) => r.isDone).toList();

    final hero = RemindersHeroHeader(
      vehicle: vehicle,
      pendingCount: pending.length,
      totalCount: reminders.length,
    );

    if (reminders.isEmpty) {
      return Column(
        children: [
          hero,
          Expanded(
            child: RemindersEmptyState(
              onAdd: () =>
                  context.push('/vehicles/${vehicle.id}/reminders/new'),
            ),
          ),
        ],
      );
    }

    // Constrói lista plana de slivers: hero + seção pendentes + seção concluídos.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: hero),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.huge + AppSpacing.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              _buildItems(context, ref, pending, done),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildItems(
    BuildContext context,
    WidgetRef ref,
    List<Reminder> pending,
    List<Reminder> done,
  ) {
    final items = <Widget>[];

    // --- Seção PENDENTES ---
    if (pending.isNotEmpty) {
      items.add(
        _SectionHeader(
          label: 'PENDENTES',
          count: pending.length,
          isPrimary: true,
        ),
      );
      for (final r in pending) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _DismissibleReminderCard(reminder: r, vehicleId: vehicle.id),
          ),
        );
      }
    }

    // --- Seção CONCLUÍDOS ---
    if (done.isNotEmpty) {
      items.add(
        _SectionHeader(
          label: 'CONCLUÍDOS',
          count: done.length,
          isPrimary: false,
        ),
      );
      for (final r in done) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _DismissibleReminderCard(reminder: r, vehicleId: vehicle.id),
          ),
        );
      }
    }

    return items;
  }
}

// ---------------------------------------------------------------------------
// Eyebrow de seção
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.isPrimary,
  });

  final String label;
  final int count;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: isPrimary ? context.inkMuted : context.inkSoft,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.brand.withValues(alpha: 0.08)
                  : context.surfaceSunken,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.pill),
              ),
            ),
            child: Text(
              '$count',
              style: textTheme.labelSmall?.copyWith(
                color: isPrimary ? AppColors.brand : context.inkSoft,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dismissible card
// ---------------------------------------------------------------------------

class _DismissibleReminderCard extends ConsumerWidget {
  const _DismissibleReminderCard({
    required this.reminder,
    required this.vehicleId,
  });

  final Reminder reminder;
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('reminder-${reminder.id}'),
      direction: DismissDirection.endToStart,
      background: const _DismissBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await ref.read(reminderSaverProvider).delete(reminder.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('"${reminder.title}" foi excluído.'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(AppSpacing.lg),
              ),
            );
        }
      },
      child: ReminderCard(
        reminder: reminder,
        onTap: () =>
            context.push('/vehicles/$vehicleId/reminders/${reminder.id}/edit'),
        onToggleDone: () =>
            ref.read(reminderSaverProvider).toggleDone(reminder),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir lembrete?'),
        content: Text(
          '"${reminder.title}" será removido. '
          'Pode ser recuperado depois nas configurações.',
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

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

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
              'Não foi possível carregar os lembretes.',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: textTheme.bodySmall,
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
