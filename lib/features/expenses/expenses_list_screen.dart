// Tela de lista de despesas — redesign editorial (Tranche C3).
//
// Design:
// - AppBar transparente que sela ao rolar (scrolledUnderElevation → sombra).
// - Hero panel brand escuro com gasto total dos últimos 30 dias em metric grande.
// - Lista agrupada por mês ("MAIO/2026" como eyebrow de seção).
// - Cards editoriais: data eyebrow · descrição bold · valor R$ em destaque ·
//   chip de categoria colorido · odômetro opcional.
// - Swipe endToStart para excluir (Dismissible, mesmo padrão B1/B2).
// - FAB extended "Nova despesa" em accent lima.
// - Empty state convidativo com CTA inline.
//
// Cálculo dos 30 dias: feito local na apresentação — não muda o data flow
// (StreamProvider já existente). Provider: expensesByVehicleProvider.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/responsive_body.dart';
import 'package:autolog/core/design/widgets/skeleton.dart';
import 'package:autolog/data/repositories/expense_repository.dart';
import 'package:autolog/domain/models/expense.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/expenses/expense_saver.dart';
import 'package:autolog/features/expenses/widgets/expense_card.dart';
import 'package:autolog/features/expenses/widgets/expenses_empty_state.dart';
import 'package:autolog/features/expenses/widgets/expenses_hero_header.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Provider reativo para a lista de despesas de um veículo.
///
/// Emite a cada mudança no banco local (Drift watch).
final expensesByVehicleProvider = StreamProvider.family<List<Expense>, String>((
  ref,
  vehicleId,
) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchByVehicle(vehicleId);
});

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

class ExpensesListScreen extends ConsumerWidget {
  const ExpensesListScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesByVehicleProvider(vehicle.id));

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
        // Título compacto revelado só ao rolar (appbar selada).
        title: Text(
          'Despesas',
          style: AppTypography.body(
            17,
            weight: FontWeight.w600,
            color: AppColors.brandInk,
          ),
        ),
        // Ícones brancos sobre o painel brand.
        foregroundColor: AppColors.brandInk,
        iconTheme: const IconThemeData(color: AppColors.brandInk),
      ),
      body: expensesAsync.when(
        loading: () => const _ExpensesSkeleton(),
        error: (error, _) => _ErrorState(
          onRetry: () => ref.invalidate(expensesByVehicleProvider(vehicle.id)),
        ),
        data: (expenses) => _Body(vehicle: vehicle, expenses: expenses),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/${vehicle.id}/expenses/new'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nova despesa'),
        tooltip: 'Adicionar despesa',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _Body extends ConsumerWidget {
  const _Body({required this.vehicle, required this.expenses});

  final Vehicle vehicle;
  final List<Expense> expenses;

  /// Agrupa despesas por mês (mais recente primeiro).
  /// Retorna lista de [(label, [expenses])] ordenada decrescente.
  List<({String label, List<Expense> items})> _groupByMonth(
    List<Expense> expenses,
  ) {
    final map = <String, List<Expense>>{};
    final order = <String>[];

    for (final e in expenses) {
      final key = DateFormat('MMMM/yyyy', 'pt_BR').format(e.date).toUpperCase();
      if (!map.containsKey(key)) {
        map[key] = [];
        order.add(key);
      }
      map[key]!.add(e);
    }

    return order.map((k) => (label: k, items: map[k]!)).toList();
  }

  /// Soma e conta despesas dos últimos 30 dias.
  ({Decimal total, int count}) _last30DaysStats(List<Expense> expenses) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    var total = Decimal.zero;
    var count = 0;
    for (final e in expenses) {
      if (e.date.isAfter(cutoff)) {
        total = total + e.amount;
        count++;
      }
    }
    return (total: total, count: count);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = _last30DaysStats(expenses);

    // Centraliza conteúdo abaixo do hero em ResponsiveWidths.content (720).
    // Hero e AppBar ficam fora — continuam full-width.
    Widget center(Widget child) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ResponsiveWidths.content),
        child: child,
      ),
    );

    // Hero always visible (mesmo no empty state, para dar contexto do veículo).
    final hero = ExpensesHeroHeader(
      vehicle: vehicle,
      totalLast30Days: stats.total,
      countLast30Days: stats.count,
    );

    if (expenses.isEmpty) {
      return Column(
        children: [
          // SafeArea top só nesta primeira coluna — o hero cobre a status bar.
          hero,
          Expanded(child: center(const ExpensesEmptyState())),
        ],
      );
    }

    final groups = _groupByMonth(expenses);

    // Constrói a lista plana de itens: [sectionHeader, card, card, …]
    // usando um CustomScrollView + SliverList para integrar o hero no scroll.
    final sliverItems = <Widget>[];
    final currentYear = DateTime.now().year;

    for (final group in groups) {
      sliverItems.add(center(_MonthSectionHeader(label: group.label)));
      for (final expense in group.items) {
        final showYear = expense.date.year != currentYear;
        sliverItems.add(
          center(
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _DismissibleExpenseCard(
                expense: expense,
                vehicleId: vehicle.id,
                showYear: showYear,
              ),
            ),
          ),
        );
      }
    }

    return CustomScrollView(
      slivers: [
        // Hero como sliver — rola com o conteúdo, full-width.
        SliverToBoxAdapter(child: hero),

        // Lista de grupos.
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.huge + AppSpacing.xl, // espaço pro FAB extended
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => sliverItems[i],
              childCount: sliverItems.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Eyebrow de seção de mês
// ---------------------------------------------------------------------------

class _MonthSectionHeader extends StatelessWidget {
  const _MonthSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: context.inkMuted,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dismissible card
// ---------------------------------------------------------------------------

class _DismissibleExpenseCard extends ConsumerWidget {
  const _DismissibleExpenseCard({
    required this.expense,
    required this.vehicleId,
    this.showYear = false,
  });

  final Expense expense;
  final String vehicleId;
  final bool showYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: const _DismissBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await ref.read(expenseSaverProvider).delete(expense.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('"${expense.description}" foi excluída.'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(AppSpacing.lg),
              ),
            );
        }
      },
      child: ExpenseCard(
        expense: expense,
        showYear: showYear,
        onTap: () =>
            context.push('/vehicles/$vehicleId/expenses/${expense.id}/edit'),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir despesa?'),
        content: Text(
          '"${expense.description}" será removida. '
          'Pode ser recuperada depois nas configurações.',
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
// Skeleton de carregamento da lista de despesas
// ---------------------------------------------------------------------------

class _ExpensesSkeleton extends StatelessWidget {
  const _ExpensesSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLine(width: 80, height: 11),
          SizedBox(height: AppSpacing.sm),
          SkeletonListCard(showTrailing: true),
          SizedBox(height: AppSpacing.md),
          SkeletonListCard(showTrailing: true),
          SizedBox(height: AppSpacing.md),
          SkeletonListCard(showTrailing: true),
          SizedBox(height: AppSpacing.xl),
          SkeletonLine(width: 80, height: 11),
          SizedBox(height: AppSpacing.sm),
          SkeletonListCard(showTrailing: true),
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
              'Não foi possível carregar as despesas.',
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
