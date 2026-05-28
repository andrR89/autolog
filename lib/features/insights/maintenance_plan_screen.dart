// Tela de Plano de Manutenção Sugerido — sugestões da IA com base no modelo do veículo.
//
// Estados:
//   - empty: CTA "Gerar plano de manutenção" (antes de gerar).
//   - loading: spinner enquanto o backend processa.
//   - success: lista de cards com itens de manutenção.
//   - quotaError: MaterialBanner de cota esgotada.
//   - genericError: snackbar de erro, volta ao empty state.
//
// Cada item tem botões "Criar lembrete" e "Ignorar".
// Dedupe aplicado: não propõe itens que já têm reminder ativo com mesmo título.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/data/repositories/fuel_entry_repository.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fuel_entry.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/fuel/fuel_history_screen.dart';
import 'package:autolog/features/insights/dedupe.dart';
import 'package:autolog/features/insights/history_insights.dart';
import 'package:autolog/features/insights/maintenance_schedule.dart';
import 'package:autolog/features/insights/maintenance_suggestion_service.dart';
import 'package:autolog/features/scan/scan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Provider de lembretes ativos do veículo (para dedupe)
// ---------------------------------------------------------------------------

/// Stream reativo: emite a cada insert/update/delete de reminder pelo Drift.
/// Evita cache estale do FutureProvider entre navegações (regressão fiscal).
final _maintenanceActiveRemindersProvider =
    StreamProvider.family<List<Reminder>, String>((ref, vehicleId) {
      final repo = ref.watch(reminderRepositoryProvider);
      return repo.watchByVehicle(vehicleId);
    });

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

/// Tela de Plano de Manutenção Sugerido para o veículo dado.
///
/// Acesso: `/vehicles/:vehicleId/insights/maintenance`.
class MaintenancePlanScreen extends ConsumerStatefulWidget {
  const MaintenancePlanScreen({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<MaintenancePlanScreen> createState() =>
      _MaintenancePlanScreenState();
}

enum _ScreenState { empty, loading, success, quotaError, genericError }

class _MaintenancePlanScreenState extends ConsumerState<MaintenancePlanScreen> {
  _ScreenState _state = _ScreenState.empty;

  // Items visíveis após dedupe e remoções otimistas.
  List<MaintenanceItem> _visibleItems = [];

  // Track which items have been created (by index in original list).
  final Set<MaintenanceItem> _created = {};
  final Set<MaintenanceItem> _ignored = {};

  Future<void> _generate() async {
    setState(() => _state = _ScreenState.loading);
    try {
      final svc = ref.read(maintenanceSuggestionServiceProvider);
      final v = widget.vehicle;

      // Compute currentOdometerKm from local fuel entries (max odometer).
      final fuels =
          ref
              .read(fuelEntriesByVehicleProvider(widget.vehicle.id))
              .valueOrNull ??
          const <FuelEntry>[];
      final currentOdometerKm = fuels.isEmpty
          ? null
          : fuels.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);

      final schedule = await svc.suggest(
        type: v.type,
        make: v.make ?? '',
        model: v.model ?? '',
        year: v.year ?? DateTime.now().year,
        engineDisplacementCc: v.engineDisplacementCc,
        tankCapacityL: v.tankCapacityL,
        vehicleUf: v.uf,
        currentOdometerKm: currentOdometerKm,
      );

      // Dedupe contra lembretes ativos.
      final remindersAsync = ref.read(
        _maintenanceActiveRemindersProvider(widget.vehicle.id),
      );
      final existing = remindersAsync.valueOrNull ?? [];

      // Convert MaintenanceItem → ProposedReminder for dedupe (title-only match).
      final proposed = schedule.items
          .map((item) => ProposedReminder(title: item.task, rationale: ''))
          .toList();
      final deduped = dedupeProposed(proposed, existing);
      final dedupedTitles = deduped.map((p) => normalizeTitle(p.title)).toSet();

      // Filter items to only those that survived dedupe.
      final filteredItems = schedule.items
          .where((item) => dedupedTitles.contains(normalizeTitle(item.task)))
          .toList();

      setState(() {
        _state = _ScreenState.success;
        _visibleItems = List.of(filteredItems);
        _created.clear();
        _ignored.clear();
      });
    } on QuotaExhaustedException {
      setState(() => _state = _ScreenState.quotaError);
    } on ScanException {
      setState(() => _state = _ScreenState.genericError);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Não conseguimos gerar o plano agora. Tente em alguns minutos.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        setState(() => _state = _ScreenState.empty);
      }
    }
  }

  Future<void> _createReminder(MaintenanceItem item) async {
    // Remoção otimista imediata.
    setState(() {
      _visibleItems.remove(item);
      _created.add(item);
    });

    try {
      final repo = ref.read(reminderRepositoryProvider);
      final now = DateTime.now().toUtc();

      Future<int> getCurrentMaxOdometer() async {
        final entries = await ref
            .read(fuelEntryRepositoryProvider)
            .listByVehicle(widget.vehicle.id);
        if (entries.isEmpty) return widget.vehicle.initialOdometer;
        return entries.map((e) => e.odometer).reduce((a, b) => a > b ? a : b);
      }

      if (item.cadenceType == 'km_or_months') {
        // Cria 2 reminders: um por km e um por data.
        final maxOdometer = await getCurrentMaxOdometer();

        final idKm = const Uuid().v4();
        final reminderKm = Reminder(
          id: idKm,
          vehicleId: widget.vehicle.id,
          type: ReminderType.porKm,
          title: '${item.task} (km)',
          dueDate: null,
          dueKm: maxOdometer + (item.everyKm ?? 10000),
          isDone: false,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          syncStatus: SyncStatus.pending,
        );
        await repo.create(reminderKm);

        final idDate = const Uuid().v4();
        final dueDate = now.add(Duration(days: (item.everyMonths ?? 12) * 30));
        final reminderDate = Reminder(
          id: idDate,
          vehicleId: widget.vehicle.id,
          type: ReminderType.porData,
          title: '${item.task} (data)',
          dueDate: dueDate,
          dueKm: null,
          isDone: false,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          syncStatus: SyncStatus.pending,
        );
        await repo.create(reminderDate);
      } else if (item.cadenceType == 'km') {
        final maxOdometer = await getCurrentMaxOdometer();
        final id = const Uuid().v4();
        final reminder = Reminder(
          id: id,
          vehicleId: widget.vehicle.id,
          type: ReminderType.porKm,
          title: item.task,
          dueDate: null,
          dueKm: maxOdometer + (item.everyKm ?? 10000),
          isDone: false,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          syncStatus: SyncStatus.pending,
        );
        await repo.create(reminder);
      } else {
        // months
        final id = const Uuid().v4();
        final dueDate = now.add(Duration(days: (item.everyMonths ?? 12) * 30));
        final reminder = Reminder(
          id: id,
          vehicleId: widget.vehicle.id,
          type: ReminderType.porData,
          title: item.task,
          dueDate: dueDate,
          dueKm: null,
          isDone: false,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          syncStatus: SyncStatus.pending,
        );
        await repo.create(reminder);
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('"${item.task}" adicionado aos lembretes.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (_) {
      // Reverte remoção otimista em caso de erro.
      if (mounted) {
        setState(() {
          _visibleItems.add(item);
          _created.remove(item);
        });
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

  void _ignoreItem(MaintenanceItem item) {
    setState(() {
      _visibleItems.remove(item);
      _ignored.add(item);
    });
  }

  Future<void> _createAll() async {
    final remaining = List.of(_visibleItems);
    for (final item in remaining) {
      await _createReminder(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final title =
        'Manutenção sugerida pra ${v.make ?? ''} ${v.model ?? ''} ${v.year ?? ''}'
            .trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano de manutenção'),
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
      floatingActionButton:
          _state == _ScreenState.success && _visibleItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _createAll,
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.brandInk,
              icon: const Icon(Icons.playlist_add_check, size: 20),
              label: const Text('Criar todos restantes'),
            )
          : null,
      body: switch (_state) {
        _ScreenState.empty || _ScreenState.genericError => _EmptyState(
          title: title,
          vehicleName: '${v.make ?? ''} ${v.model ?? ''}'.trim(),
          onGenerate: _generate,
        ),
        _ScreenState.loading => const _LoadingState(),
        _ScreenState.success => _SuccessBody(
          items: _visibleItems,
          onCreate: _createReminder,
          onIgnore: _ignoreItem,
        ),
        _ScreenState.quotaError => _QuotaBannerState(onGenerate: _generate),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.vehicleName,
    required this.onGenerate,
  });

  final String title;
  final String vehicleName;
  final VoidCallback onGenerate;

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
                  Icons.build_outlined,
                  size: 32,
                  color: context.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Plano de manutenção',
                style: AppTypography.display(
                  22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                vehicleName.isNotEmpty
                    ? 'Gerar plano de manutenção sugerido pra $vehicleName'
                    : 'Gerar plano de manutenção sugerido para este veículo',
                style: textTheme.bodyMedium?.copyWith(color: context.inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Usa a mesma cota de análises (3/mês no gratuito).',
                style: textTheme.bodySmall?.copyWith(color: context.inkSoft),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Gerar plano de manutenção sugerido'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: AppColors.brandInk,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Consultando IA...',
            style: textTheme.bodyMedium?.copyWith(color: context.inkMuted),
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
  const _QuotaBannerState({required this.onGenerate});

  final VoidCallback onGenerate;

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
            TextButton(onPressed: onGenerate, child: const Text('Fechar')),
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
    required this.items,
    required this.onCreate,
    required this.onIgnore,
  });

  final List<MaintenanceItem> items;
  final Future<void> Function(MaintenanceItem) onCreate;
  final void Function(MaintenanceItem) onIgnore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Text(
            'Todos os itens de manutenção já foram adicionados ou ignorados.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.inkMuted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.huge + 80, // space for FAB
      ),
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) => _MaintenanceItemCard(
        item: items[i],
        onCreate: () => onCreate(items[i]),
        onIgnore: () => onIgnore(items[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Maintenance item card
// ---------------------------------------------------------------------------

class _MaintenanceItemCard extends StatelessWidget {
  const _MaintenanceItemCard({
    required this.item,
    required this.onCreate,
    required this.onIgnore,
  });

  final MaintenanceItem item;
  final VoidCallback onCreate;
  final VoidCallback onIgnore;

  String _formatCadence() {
    switch (item.cadenceType) {
      case 'km':
        final km = item.everyKm;
        if (km == null) return 'Cadência por km';
        return 'A cada ${_formatKm(km)} km';
      case 'months':
        final m = item.everyMonths;
        if (m == null) return 'Cadência por tempo';
        return 'A cada $m ${m == 1 ? 'mês' : 'meses'}';
      case 'km_or_months':
        final km = item.everyKm;
        final m = item.everyMonths;
        if (km != null && m != null) {
          return 'A cada ${_formatKm(km)} km ou $m ${m == 1 ? 'mês' : 'meses'}, o que vier primeiro';
        }
        if (km != null) return 'A cada ${_formatKm(km)} km';
        if (m != null) return 'A cada $m ${m == 1 ? 'mês' : 'meses'}';
        return 'Cadência variável';
      default:
        return item.cadenceType;
    }
  }

  String _formatKm(int km) {
    // Format with thousands separator for readability.
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(km % 1000 == 0 ? 0 : 1).replaceAll('.', ',')}k';
    }
    return km.toString();
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.task,
            style: AppTypography.body(
              15,
              weight: FontWeight.w600,
              color: context.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                item.cadenceType == 'months'
                    ? Icons.calendar_today_outlined
                    : Icons.speed_outlined,
                size: 14,
                color: context.inkSoft,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _formatCadence(),
                  style: textTheme.bodySmall?.copyWith(color: context.inkMuted),
                ),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.notes!,
              style: textTheme.bodySmall?.copyWith(color: context.inkSoft),
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
