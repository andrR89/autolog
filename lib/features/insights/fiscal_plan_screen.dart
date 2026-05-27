// Tela de Lembretes Fiscais (IPVA + Licenciamento) por UF e final de placa.
//
// Sprint 6.W.3: substituído lookup hardcoded por FiscalLookupService (IA + cache).
// Fallback: se IA falhar, usa calendário hardcoded (FallbackComputer).
//
// Disclaimer obrigatório: "Confira com seu Detran".

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/insights/dedupe.dart';
import 'package:autolog/features/insights/fiscal_calendar.dart';
import 'package:autolog/features/insights/fiscal_lookup_result.dart';
import 'package:autolog/features/insights/fiscal_lookup_service.dart';
import 'package:autolog/features/insights/history_insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Provider de lembretes ativos do veículo (para dedupe)
// ---------------------------------------------------------------------------

/// Lembretes ativos do veículo via `watchByVehicle` — Stream reativa.
final _fiscalActiveRemindersProvider =
    StreamProvider.family<List<Reminder>, String>((ref, vehicleId) {
      final repo = ref.watch(reminderRepositoryProvider);
      return repo.watchByVehicle(vehicleId);
    });

// ---------------------------------------------------------------------------
// Provider do resultado do lookup fiscal
// ---------------------------------------------------------------------------

/// Parâmetros para o lookup fiscal.
class _FiscalLookupParams {
  const _FiscalLookupParams({
    required this.uf,
    required this.plateLastDigit,
    required this.year,
  });

  final String uf;
  final int plateLastDigit;
  final int year;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FiscalLookupParams &&
          uf == other.uf &&
          plateLastDigit == other.plateLastDigit &&
          year == other.year;

  @override
  int get hashCode => Object.hash(uf, plateLastDigit, year);
}

final _fiscalLookupProvider =
    FutureProvider.family<FiscalLookupResult, _FiscalLookupParams>(
      (ref, params) {
        final service = ref.watch(fiscalLookupServiceProvider);
        return service.lookup(
          uf: params.uf,
          plateLastDigit: params.plateLastDigit,
          year: params.year,
        );
      },
    );

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

/// Tela de lembretes fiscais (IPVA + Licenciamento) para o veículo dado.
class FiscalPlanScreen extends ConsumerStatefulWidget {
  const FiscalPlanScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<FiscalPlanScreen> createState() => _FiscalPlanScreenState();
}

class _FiscalPlanScreenState extends ConsumerState<FiscalPlanScreen> {
  final Set<String> _ignoredTitles = {};

  /// Constrói propostas a partir do resultado do lookup fiscal.
  List<_FiscalProposal> _buildProposals(
    FiscalLookupResult result,
    List<Reminder> activeReminders,
  ) {
    final v = widget.vehicle;
    final year = DateTime.now().year;

    final ipvaDate = DateTime.utc(year, result.ipva.month, result.ipva.day ?? 1);
    final licDate = DateTime.utc(year, result.licensing.month, result.licensing.day ?? 1);

    final proposed = [
      ProposedReminder(
        title: 'IPVA $year',
        dueDate: ipvaDate,
        rationale: _buildRationale(v.uf, result.source, result.ipva.sourceCitation),
      ),
      ProposedReminder(
        title: 'Licenciamento $year',
        dueDate: licDate,
        rationale: _buildRationale(v.uf, result.source, result.licensing.sourceCitation),
      ),
    ];

    final deduped = dedupeProposed(proposed, activeReminders);
    final filtered = deduped
        .where((p) => !_ignoredTitles.contains(normalizeTitle(p.title)))
        .toList();

    // Map para associar source info a cada proposta.
    return filtered.map((p) {
      final isIpva = p.title.startsWith('IPVA');
      final entry = isIpva ? result.ipva : result.licensing;
      return _FiscalProposal(
        reminder: p,
        source: result.source,
        sourceCitation: entry.sourceCitation,
      );
    }).toList();
  }

  String _buildRationale(
    String? uf,
    FiscalLookupSource source,
    String? citation,
  ) {
    if (source == FiscalLookupSource.localFallback) {
      return 'Estimativa local — confira no Detran do seu estado.';
    }
    if (citation != null && citation.isNotEmpty) {
      return 'Fonte: $citation — confira no Detran.';
    }
    return 'Fonte: IA — confira no Detran.';
  }

  Future<void> _createReminder(ProposedReminder proposed) async {
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
      if (mounted) {
        setState(() => _ignoredTitles.remove(normalizeTitle(proposed.title)));
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

  Future<void> _createAll(List<_FiscalProposal> remaining) async {
    for (final item in remaining) {
      await _createReminder(item.reminder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final year = DateTime.now().year;
    final digit = lastDigitOfPlate(v.plate);

    // Lookup fiscal via service.
    final lookupAsync = (v.uf != null && digit != null)
        ? ref.watch(
            _fiscalLookupProvider(
              _FiscalLookupParams(uf: v.uf!, plateLastDigit: digit, year: year),
            ),
          )
        : null;

    final remindersAsync =
        ref.watch(_fiscalActiveRemindersProvider(widget.vehicle.id));

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
        actions: [
          if (_ignoredTitles.isNotEmpty)
            IconButton(
              tooltip: 'Mostrar propostas ignoradas',
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(_ignoredTitles.clear),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DisclaimerBanner(),
          _VehicleContextStrip(vehicle: widget.vehicle),
          Expanded(
            child: _buildBody(lookupAsync, remindersAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AsyncValue<FiscalLookupResult>? lookupAsync,
    AsyncValue<List<Reminder>> remindersAsync,
  ) {
    // Se não tem UF ou dígito, cai para fallback imediato.
    if (lookupAsync == null) {
      final v = widget.vehicle;
      final year = DateTime.now().year;
      final digit = lastDigitOfPlate(v.plate) ?? 0;
      final fallback = const FallbackComputer().compute(v.uf ?? '', digit, year);
      return _buildWithResult(fallback, remindersAsync);
    }

    // Loading inicial do lookup (primeira vez — cache miss).
    if (lookupAsync.isLoading && !lookupAsync.hasValue) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Resultado disponível (cache hit é instantâneo).
    final result = lookupAsync.valueOrNull;
    if (result != null) {
      return _buildWithResult(result, remindersAsync);
    }

    // Erro no lookup → fallback local imediato.
    final v = widget.vehicle;
    final year = DateTime.now().year;
    final digit = lastDigitOfPlate(v.plate) ?? 0;
    final fallback = const FallbackComputer().compute(v.uf ?? '', digit, year);
    return _buildWithResult(fallback, remindersAsync);
  }

  Widget _buildWithResult(
    FiscalLookupResult result,
    AsyncValue<List<Reminder>> remindersAsync,
  ) {
    if (remindersAsync.isLoading && !remindersAsync.hasValue) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final activeReminders = remindersAsync.valueOrNull ?? const [];
    final proposals = _buildProposals(result, activeReminders);

    if (proposals.isEmpty) {
      return _EmptyState(
        hasIgnored: _ignoredTitles.isNotEmpty,
        onResetIgnored: _ignoredTitles.isEmpty
            ? null
            : () => setState(_ignoredTitles.clear),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.huge + 80,
          ),
          itemCount: proposals.length,
          separatorBuilder: (context, _) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => _FiscalItemCard(
            proposal: proposals[i],
            onCreate: () => _createReminder(proposals[i].reminder),
            onIgnore: () => _ignoreItem(proposals[i].reminder),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton.extended(
              onPressed: () => _createAll(proposals),
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.brandInk,
              icon: const Icon(Icons.playlist_add_check, size: 20),
              label: const Text('Criar todos restantes'),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Modelo interno de proposta com metadata de fonte
// ---------------------------------------------------------------------------

class _FiscalProposal {
  const _FiscalProposal({
    required this.reminder,
    required this.source,
    this.sourceCitation,
  });

  final ProposedReminder reminder;
  final FiscalLookupSource source;
  final String? sourceCitation;
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
// Strip de contexto do veículo
// ---------------------------------------------------------------------------

class _VehicleContextStrip extends StatelessWidget {
  const _VehicleContextStrip({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final plate = vehicle.plate;
    final uf = vehicle.uf;
    final lastDigit = lastDigitOfPlate(plate);

    final parts = <String>[
      vehicle.nickname,
      if (plate != null && plate.trim().isNotEmpty) plate.trim().toUpperCase(),
      uf ?? 'sem UF',
      if (lastDigit != null) 'final $lastDigit',
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            vehicle.type == VehicleType.moto
                ? Icons.two_wheeler
                : Icons.directions_car,
            size: 18,
            color: AppColors.inkMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              parts.join(' · '),
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
  const _EmptyState({this.hasIgnored = false, this.onResetIgnored});

  final bool hasIgnored;
  final VoidCallback? onResetIgnored;

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
              hasIgnored
                  ? 'Você ignorou todas as propostas nesta sessão.'
                  : 'Lembretes já criados — você está em dia.\n'
                      'Para ver de novo, exclua um lembrete na aba '
                      '"Lembretes" e volte aqui.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            if (hasIgnored && onResetIgnored != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onResetIgnored,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Mostrar de novo'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.brandInk,
                ),
              ),
            ],
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
    required this.proposal,
    required this.onCreate,
    required this.onIgnore,
  });

  final _FiscalProposal proposal;
  final VoidCallback onCreate;
  final VoidCallback onIgnore;

  String _formatDueDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    final mon = months[date.month - 1];
    final yr = date.year.toString().substring(2);
    return 'Vence em $mon/$yr';
  }

  String _sourceLabel(_FiscalProposal p) {
    if (p.source == FiscalLookupSource.localFallback) {
      return 'fonte: estimativa local';
    }
    if (p.sourceCitation != null && p.sourceCitation!.isNotEmpty) {
      return 'fonte: IA (${p.sourceCitation})';
    }
    return 'fonte: IA';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dueLabel = _formatDueDate(proposal.reminder.dueDate);
    final sourceLabel = _sourceLabel(proposal);

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
            proposal.reminder.title,
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
          if (proposal.reminder.rationale.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              proposal.reminder.rationale,
              style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          // Chip de fonte (IA vs estimativa local).
          Chip(
            label: Text(
              sourceLabel,
              style: textTheme.labelSmall?.copyWith(
                color: proposal.source == FiscalLookupSource.localFallback
                    ? AppColors.inkSoft
                    : AppColors.brand,
              ),
            ),
            backgroundColor: proposal.source == FiscalLookupSource.localFallback
                ? AppColors.surfaceSunken
                : AppColors.brand.withValues(alpha: 0.08),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide.none,
          ),
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
