// Tela de Lembretes Fiscais (IPVA + Licenciamento) por UF e final de placa.
//
// Baseada em calendário típico hardcoded — sem IA, sem rede, sem cota.
// Disclaimer obrigatório: "Confira com seu Detran".
//
// Padrão espelhado de MaintenancePlanScreen (Sprint 6.M).

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/insights/dedupe.dart';
import 'package:autolog/features/insights/fiscal_calendar.dart';
import 'package:autolog/features/insights/history_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Provider de lembretes ativos do veículo (para dedupe)
// ---------------------------------------------------------------------------

/// Lembretes ativos do veículo via `watchByVehicle` — Stream reativa.
///
/// Regressão 26/05/2026: o `FutureProvider.family` cacheava um snapshot
/// estale após criar reminders, fazendo a tela mostrar lista vazia
/// erroneamente ao navegar entre veículos. `StreamProvider` resolve
/// porque o Drift emite nova lista a cada insert/update/delete.
final _fiscalActiveRemindersProvider =
    StreamProvider.family<List<Reminder>, String>((ref, vehicleId) {
      final repo = ref.watch(reminderRepositoryProvider);
      return repo.watchByVehicle(vehicleId);
    });

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

/// Tela de lembretes fiscais (IPVA + Licenciamento) para o veículo dado.
///
/// Acesso: `/vehicles/:vehicleId/insights/fiscal`.
class FiscalPlanScreen extends ConsumerStatefulWidget {
  const FiscalPlanScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<FiscalPlanScreen> createState() => _FiscalPlanScreenState();
}

class _FiscalPlanScreenState extends ConsumerState<FiscalPlanScreen> {
  // Títulos normalizados ignorados nesta sessão (não persiste).
  // Reativo: as propostas são derivadas no build a partir do veículo +
  // dos reminders ativos atuais (StreamProvider). Sem snapshot manual.
  final Set<String> _ignoredTitles = {};

  /// Computa as propostas visíveis pra render. Combina:
  ///   - propostas hardcoded do calendário fiscal do veículo
  ///   - dedupe contra lembretes ativos (vindos do Stream)
  ///   - exclusão de itens ignorados nesta sessão
  List<ProposedReminder> _visibleProposals(List<Reminder> activeReminders) {
    final v = widget.vehicle;
    final year = DateTime.now().year;
    final proposed = suggestFiscalReminders(
      uf: v.uf,
      plate: v.plate,
      year: year,
    );
    final deduped = dedupeProposed(proposed, activeReminders);
    return deduped
        .where((p) => !_ignoredTitles.contains(normalizeTitle(p.title)))
        .toList();
  }

  Future<void> _createReminder(ProposedReminder proposed) async {
    // Marca como ignorado otimisticamente pra sumir da lista imediato.
    // O Stream do repo vai emitir o novo Reminder em seguida e o dedupe
    // confirmar — não precisa de revert manual (idempotente).
    setState(() => _ignoredTitles.add(normalizeTitle(proposed.title)));

    final id = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final reminder = Reminder(
      id: id,
      vehicleId: widget.vehicle.id,
      type: ReminderType.porData,
      title: proposed.title,
      dueDate: proposed.dueDate,
      dueKm: null,
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
      // Reverte o ignore otimista pra item reaparecer e user tentar de novo.
      if (mounted) {
        setState(() =>
            _ignoredTitles.remove(normalizeTitle(proposed.title)));
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

  void _ignoreItem(ProposedReminder proposed) {
    setState(() => _ignoredTitles.add(normalizeTitle(proposed.title)));
  }

  Future<void> _createAll(List<ProposedReminder> remaining) async {
    for (final item in remaining) {
      await _createReminder(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reativo: o body é função do StreamProvider de reminders ativos.
    final remindersAsync =
        ref.watch(_fiscalActiveRemindersProvider(widget.vehicle.id));
    final visible = remindersAsync.maybeWhen(
      data: _visibleProposals,
      orElse: () => const <ProposedReminder>[],
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Lembretes fiscais'),
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
      ),
      floatingActionButton: visible.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _createAll(visible),
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.brandInk,
              icon: const Icon(Icons.playlist_add_check, size: 20),
              label: const Text('Criar todos restantes'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner disclaimer — OBRIGATÓRIO conforme spec.
          _DisclaimerBanner(),
          // Conteúdo.
          Expanded(child: _buildBody(visible, remindersAsync)),
        ],
      ),
    );
  }

  Widget _buildBody(
    List<ProposedReminder> visible,
    AsyncValue<List<Reminder>> remindersAsync,
  ) {
    // Loading inicial (Stream ainda não emitiu) → spinner discreto.
    if (remindersAsync.isLoading && !remindersAsync.hasValue) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (visible.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge + 80, // espaço pro FAB
      ),
      itemCount: visible.length,
      separatorBuilder: (context, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => _FiscalItemCard(
        proposed: visible[i],
        onCreate: () => _createReminder(visible[i]),
        onIgnore: () => _ignoreItem(visible[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banner disclaimer (obrigatório)
// ---------------------------------------------------------------------------

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: AppColors.surfaceSunken,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.inkSoft),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Datas baseadas em calendário típico. ',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  TextSpan(
                    text: 'Confira com seu Detran',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' — datas variam por ano e por dígito da placa.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppColors.inkSoft,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Lembretes já criados — você está em dia.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card de item fiscal
// ---------------------------------------------------------------------------

class _FiscalItemCard extends StatelessWidget {
  const _FiscalItemCard({
    required this.proposed,
    required this.onCreate,
    required this.onIgnore,
  });

  final ProposedReminder proposed;
  final VoidCallback onCreate;
  final VoidCallback onIgnore;

  String _formatDueDate(DateTime? date) {
    if (date == null) return '';
    // Formata como "jan/26", "mar/2026" etc.
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    final mon = months[date.month - 1];
    final yr = date.year.toString().substring(2); // '26' de 2026
    return 'Vence em $mon/$yr';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dueLabel = _formatDueDate(proposed.dueDate);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.hairline),
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
              color: AppColors.ink,
            ),
          ),
          if (dueLabel.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.inkSoft,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  dueLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ],
          if (proposed.rationale.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              proposed.rationale,
              style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
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
                child: const Text('Criar lembrete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
