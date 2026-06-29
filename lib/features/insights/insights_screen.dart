// Tela de Insights — análise sob demanda do histórico do veículo via IA.
//
// Estados:
//   - empty: CTA "Analisar agora" (antes de rodar a análise).
//   - loading: spinner enquanto o backend processa.
//   - sucesso: 2 seções — "Padrões detectados" e "Lembretes sugeridos".
//   - QuotaExhaustedException: MaterialBanner de cota esgotada.
//   - ScanException: snackbar de erro.
//
// Lembretes sugeridos passam por dedupeProposed antes de serem exibidos.
// Criar lembrete: ReminderRepository.create() + remoção otimista da lista.

import 'dart:async';

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/skeleton.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/insights/dedupe.dart';
import 'package:autolog/features/insights/history_insights.dart';
import 'package:autolog/features/insights/insights_service.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:autolog/features/tts/insight_narrator.dart';
import 'package:autolog/features/tts/widgets/tts_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Provider de lembretes ativos do veículo (para dedupe)
// ---------------------------------------------------------------------------

/// Stream reativo de lembretes ativos. Antes era `FutureProvider`, mas o
/// snapshot ficava estale após `repo.create(reminder)` — segunda análise
/// dedupava contra lista vazia (não filtrava o que acabou de ser criado).
/// `StreamProvider` + `watchByVehicle` emite a cada mudança do Drift.
/// (Regressão 27/05/2026 — mesma classe do fix em fiscal/maintenance.)
final _activeRemindersProvider = StreamProvider.family<List<Reminder>, String>((
  ref,
  vehicleId,
) {
  final repo = ref.watch(reminderRepositoryProvider);
  return repo.watchByVehicle(vehicleId);
});

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

/// Tela de Insights de IA para o veículo dado.
///
/// Acesso: `/vehicles/:vehicleId/insights`.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

enum _ScreenState { empty, loading, success, quotaError, genericError }

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  _ScreenState _state = _ScreenState.empty;
  HistoryInsights? _result;

  // Lembretes sugeridos exibidos (subset após dedupe, com remoções otimistas).
  List<ProposedReminder> _visibleProposed = [];

  Future<void> _analyze() async {
    setState(() => _state = _ScreenState.loading);
    try {
      final svc = ref.read(insightsServiceProvider);
      final result = await svc.analyze(widget.vehicle.id);

      // Dedupe contra lembretes ativos — usa `.future` pra aguardar o Stream
      // emitir o valor mais recente (importante quando user acabou de criar
      // reminders e clica "Analisar" de novo).
      final existing = await ref.read(
        _activeRemindersProvider(widget.vehicle.id).future,
      );
      final deduped = dedupeProposed(result.proposedReminders, existing);

      setState(() {
        _state = _ScreenState.success;
        _result = result;
        _visibleProposed = List.of(deduped);
      });
    } on QuotaExhaustedException {
      setState(() => _state = _ScreenState.quotaError);
    } on ScanException {
      setState(() => _state = _ScreenState.genericError);
      unawaited(HapticFeedback.heavyImpact());
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Não conseguimos analisar agora. Tente em alguns minutos.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  Future<void> _createReminder(ProposedReminder proposed) async {
    // Remoção otimista imediata.
    setState(() => _visibleProposed.remove(proposed));

    final id = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final type = proposed.dueDate != null
        ? ReminderType.porData
        : ReminderType.porKm;

    final reminder = Reminder(
      id: id,
      vehicleId: widget.vehicle.id,
      type: type,
      title: proposed.title,
      dueDate: proposed.dueDate,
      dueKm: proposed.dueKm,
      isDone: false,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      syncStatus: SyncStatus.pending,
    );

    try {
      await ref.read(reminderRepositoryProvider).create(reminder);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('"${proposed.title}" adicionado aos lembretes.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (_) {
      // Reverte remoção otimista em caso de erro.
      if (mounted) {
        setState(() => _visibleProposed.add(proposed));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível criar o lembrete. Tente novamente.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  void _ignoreReminder(ProposedReminder proposed) {
    setState(() => _visibleProposed.remove(proposed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.hairline),
        ),
        actions: [
          if (_result != null)
            TtsButton(textBuilder: () => narrateInsights(_result!)),
        ],
      ),
      body: switch (_state) {
        _ScreenState.empty => _EmptyState(
          vehicle: widget.vehicle,
          onAnalyze: _analyze,
          onOpenChat: () =>
              context.push('/vehicles/${widget.vehicle.id}/insights/chat'),
        ),
        _ScreenState.loading => const _LoadingState(),
        _ScreenState.success => _SuccessBody(
          vehicle: widget.vehicle,
          result: _result!,
          visibleProposed: _visibleProposed,
          onAnalyzeAgain: _analyze,
          onCreate: _createReminder,
          onIgnore: _ignoreReminder,
          onOpenMaintenancePlan: () => context.push(
            '/vehicles/${widget.vehicle.id}/insights/maintenance',
          ),
          onOpenFiscalPlan: () =>
              context.push('/vehicles/${widget.vehicle.id}/insights/fiscal'),
          onOpenChat: () =>
              context.push('/vehicles/${widget.vehicle.id}/insights/chat'),
        ),
        _ScreenState.quotaError => _QuotaBannerState(
          vehicle: widget.vehicle,
          onAnalyze: _analyze,
        ),
        _ScreenState.genericError => _EmptyState(
          vehicle: widget.vehicle,
          onAnalyze: _analyze,
          onOpenChat: () =>
              context.push('/vehicles/${widget.vehicle.id}/insights/chat'),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.vehicle,
    required this.onAnalyze,
    required this.onOpenChat,
  });

  final Vehicle vehicle;
  final VoidCallback onAnalyze;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.surfaceSunken,
                  borderRadius: AppRadius.allLg,
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  size: 32,
                  color: context.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Insights do histórico',
                style: AppTypography.display(
                  22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A IA analisa seus abastecimentos e despesas dos últimos 3 anos '
                'e sugere padrões e lembretes proativos.',
                style: textTheme.bodyMedium?.copyWith(color: context.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Cota: 3 análises/mês no plano gratuito.',
                style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Analisar agora'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: AppColors.brandInk,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/vehicles/${vehicle.id}/insights/maintenance',
                  ),
                  icon: const Icon(Icons.build_outlined, size: 18),
                  label: const Text('Plano de manutenção sugerido'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/vehicles/${vehicle.id}/insights/fiscal'),
                  icon: const Icon(Icons.account_balance_outlined, size: 18),
                  label: const Text('Lembretes IPVA + Licenciamento'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'ASSISTENTE',
                style: textTheme.labelSmall?.copyWith(
                  color: context.inkMuted,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenChat,
                  icon: const Text('💬', style: TextStyle(fontSize: 16)),
                  label: const Text('Pergunte ao histórico'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label de seção skeleton
          const SkeletonLine(width: 140, height: 11),
          const SizedBox(height: AppSpacing.lg),
          // Cards de insight
          const SkeletonInsightCard(),
          const SizedBox(height: AppSpacing.md),
          const SkeletonInsightCard(),
          const SizedBox(height: AppSpacing.md),
          const SkeletonInsightCard(),
          const SizedBox(height: AppSpacing.xxl),
          // Label da segunda seção
          const SkeletonLine(width: 160, height: 11),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonInsightCard(),
          const SizedBox(height: AppSpacing.md),
          const SkeletonInsightCard(),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              'Analisando histórico...',
              style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quota error state
// ---------------------------------------------------------------------------

class _QuotaBannerState extends StatelessWidget {
  const _QuotaBannerState({required this.vehicle, required this.onAnalyze});

  final Vehicle vehicle;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        MaterialBanner(
          backgroundColor: AppColors.warningSoft,
          content: Text(
            'Cota mensal de análises esgotada — vire premium pra ilimitado.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.warning),
          ),
          leading: const Icon(Icons.info_outline, color: AppColors.warning),
          actions: [
            TextButton(onPressed: onAnalyze, child: const Text('Fechar')),
          ],
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: Text(
                'Sem análises disponíveis este mês.\nAssine o plano premium para análises ilimitadas.',
                style: textTheme.bodyMedium?.copyWith(color: context.inkMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Success body
// ---------------------------------------------------------------------------

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.vehicle,
    required this.result,
    required this.visibleProposed,
    required this.onAnalyzeAgain,
    required this.onCreate,
    required this.onIgnore,
    required this.onOpenMaintenancePlan,
    required this.onOpenFiscalPlan,
    required this.onOpenChat,
  });

  final Vehicle vehicle;
  final HistoryInsights result;
  final List<ProposedReminder> visibleProposed;
  final VoidCallback onAnalyzeAgain;
  final Future<void> Function(ProposedReminder) onCreate;
  final void Function(ProposedReminder) onIgnore;
  final VoidCallback onOpenMaintenancePlan;
  final VoidCallback onOpenFiscalPlan;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Seção Padrões detectados
        if (result.patterns.isNotEmpty)
          SliverToBoxAdapter(
            child: _SectionHeader(
              label: 'PADRÕES DETECTADOS',
              count: result.patterns.length,
            ),
          ),
        if (result.patterns.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.builder(
              itemCount: result.patterns.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _PatternCard(pattern: result.patterns[i]),
              ),
            ),
          ),
        if (result.patterns.isEmpty)
          const SliverToBoxAdapter(
            child: _EmptySectionHint(
              message: 'Nenhum padrão identificado no histórico.',
            ),
          ),

        // Seção Lembretes sugeridos
        SliverToBoxAdapter(
          child: _SectionHeader(
            label: 'LEMBRETES SUGERIDOS',
            count: visibleProposed.length,
          ),
        ),
        if (visibleProposed.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverList.builder(
              itemCount: visibleProposed.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _ProposedReminderCard(
                  proposed: visibleProposed[i],
                  onCreate: () => onCreate(visibleProposed[i]),
                  onIgnore: () => onIgnore(visibleProposed[i]),
                ),
              ),
            ),
          ),
        if (visibleProposed.isEmpty)
          const SliverToBoxAdapter(
            child: _EmptySectionHint(
              message: 'Todos os lembretes sugeridos já foram criados.',
            ),
          ),

        // Seção Plano de manutenção sugerido
        const SliverToBoxAdapter(
          child: _SectionHeader(label: 'MANUTENÇÃO', count: 0),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: _MaintenancePlanCard(onOpen: onOpenMaintenancePlan),
          ),
        ),

        // Seção Fiscal (IPVA + Licenciamento)
        const SliverToBoxAdapter(
          child: _SectionHeader(label: 'FISCAL', count: 0),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: _FiscalPlanCard(onOpen: onOpenFiscalPlan),
          ),
        ),

        // Seção Assistente
        const SliverToBoxAdapter(
          child: _SectionHeader(label: 'ASSISTENTE', count: 0),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: _ChatAssistantCard(onOpen: onOpenChat),
          ),
        ),

        // Botão "Analisar novamente"
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.huge,
            ),
            child: OutlinedButton.icon(
              onPressed: onAnalyzeAgain,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Analisar novamente'),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: context.inkMuted,
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
              color: context.surfaceSunken,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.pill),
              ),
            ),
            child: Text(
              '$count',
              style: textTheme.labelSmall?.copyWith(
                color: context.inkSoft,
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
// Pattern card
// ---------------------------------------------------------------------------

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final DetectedPattern pattern;

  String get _cadenceLabel => switch (pattern.cadence) {
    'yearly' => 'Anual',
    'monthly' => 'Mensal',
    _ => pattern.cadence,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final confidencePct = (pattern.confidence * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pattern.category,
                  style: AppTypography.body(
                    15,
                    weight: FontWeight.w600,
                    color: context.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceSunken,
                  borderRadius: AppRadius.allSm,
                ),
                child: Text(
                  _cadenceLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: context.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Confiança: $confidencePct%',
            style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
          ),
          if (pattern.rationale != null && pattern.rationale!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              pattern.rationale!,
              style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Proposed reminder card
// ---------------------------------------------------------------------------

class _ProposedReminderCard extends StatelessWidget {
  const _ProposedReminderCard({
    required this.proposed,
    required this.onCreate,
    required this.onIgnore,
  });

  final ProposedReminder proposed;
  final VoidCallback onCreate;
  final VoidCallback onIgnore;

  String? get _dueLine {
    if (proposed.dueDate != null) {
      final d = proposed.dueDate!;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    if (proposed.dueKm != null) {
      return '${proposed.dueKm} km';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dueLine = _dueLine;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            proposed.title,
            style: AppTypography.body(
              15,
              weight: FontWeight.w600,
              color: context.ink,
            ),
          ),
          if (dueLine != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  proposed.dueDate != null
                      ? Icons.calendar_today_outlined
                      : Icons.speed_outlined,
                  size: 14,
                  color: context.inkSoft,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  dueLine,
                  style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
                ),
              ],
            ),
          ],
          if (proposed.rationale.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              proposed.rationale,
              style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onIgnore, child: const Text('Ignorar')),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: onCreate,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.brandInk,
                ),
                child: const Text('Criar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Maintenance plan card
// ---------------------------------------------------------------------------

class _MaintenancePlanCard extends StatelessWidget {
  const _MaintenancePlanCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.build_outlined, size: 24, color: context.inkMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plano de manutenção sugerido',
                  style: AppTypography.body(
                    15,
                    weight: FontWeight.w600,
                    color: context.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Veja as manutenções típicas para o seu veículo.',
                  style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.brandInk,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty section hint
// ---------------------------------------------------------------------------

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Text(
        message,
        style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat assistant card
// ---------------------------------------------------------------------------

class _ChatAssistantCard extends StatelessWidget {
  const _ChatAssistantCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const Text('💬', style: TextStyle(fontSize: 24)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pergunte ao histórico',
                  style: AppTypography.body(
                    15,
                    weight: FontWeight.w600,
                    color: context.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Converse com a IA sobre seus gastos e vencimentos.',
                  style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.brandInk,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fiscal plan card
// ---------------------------------------------------------------------------

class _FiscalPlanCard extends StatelessWidget {
  const _FiscalPlanCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 24,
            color: context.inkMuted,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lembretes IPVA + Licenciamento',
                  style: AppTypography.body(
                    15,
                    weight: FontWeight.w600,
                    color: context.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Calendário fiscal por UF e final de placa.',
                  style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.brandInk,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }
}
