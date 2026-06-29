// Tela de Documentos Pessoais — Sprint 6.O.
//
// Seções:
// - Minha CNH (1 card de perfil)
// - Apólices ativas (lista por veículo)
// - Multas pendentes (lista por veículo)
// - Botão "Sugerir lembretes" → modal com propostas

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/design/widgets/responsive_body.dart';
import 'package:autolog/core/design/widgets/skeleton.dart';
import 'package:autolog/data/repositories/fine_repository.dart';
import 'package:autolog/data/repositories/insurance_repository.dart';
import 'package:autolog/data/repositories/reminder_repository.dart';
import 'package:autolog/data/repositories/user_profile_repository.dart';
import 'package:autolog/data/repositories/vehicle_repository.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/fine.dart';
import 'package:autolog/domain/models/insurance.dart';
import 'package:autolog/domain/models/reminder.dart';
import 'package:autolog/domain/models/user_profile.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/insights/dedupe.dart';
import 'package:autolog/features/insights/history_insights.dart';
import 'package:autolog/features/personal_documents/document_reminder_suggestions.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

// ---------------------------------------------------------------------------
// Providers locais
// ---------------------------------------------------------------------------

final _userProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.watch(userProfileRepositoryProvider);
  return repo.getById(userId);
});

final _vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.listByUser(userId);
});

// ---------------------------------------------------------------------------
// Tela principal
// ---------------------------------------------------------------------------

class PersonalDocumentsScreen extends ConsumerStatefulWidget {
  const PersonalDocumentsScreen({super.key});

  @override
  ConsumerState<PersonalDocumentsScreen> createState() =>
      _PersonalDocumentsScreenState();
}

class _PersonalDocumentsScreenState
    extends ConsumerState<PersonalDocumentsScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_userProfileProvider);
    final vehiclesAsync = ref.watch(_vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: context.hairline,
        systemOverlayStyle: context.systemUiStyle,
        title: const Text('Documentos'),
        actions: [
          TextButton.icon(
            onPressed: () => _suggestReminders(context),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text('Sugerir lembretes'),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_userProfileProvider);
          ref.invalidate(_vehiclesProvider);
        },
        child: ResponsiveBody(
          child: CustomScrollView(
            slivers: [
              // ── CNH ─────────────────────────────────────────────────────────
              //
              // "Editar" só aparece quando há CNH cadastrada — sem isso, o botão
              // confunde (não há o que editar) e duplica o CTA "Cadastrar CNH"
              // da própria seção (UX 19/06).
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Minha CNH',
                  action: profileAsync.maybeWhen(
                    data: (p) {
                      final hasCnh =
                          p != null &&
                          (p.cnhNumber != null ||
                              p.cnhCategory != null ||
                              p.cnhExpiresAt != null);
                      if (!hasCnh) return null;
                      return TextButton(
                        onPressed: () =>
                            context.push('/personal-documents/cnh'),
                        child: const Text('Editar'),
                      );
                    },
                    orElse: () => null,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: profileAsync.when(
                  loading: () => const _DocsSectionSkeleton(cardCount: 1),
                  error: (_, st) => const _ErrorCard(
                    message: 'Não foi possível carregar a CNH.',
                  ),
                  data: (profile) => _CnhCard(
                    profile: profile,
                    onEdit: () => context.push('/personal-documents/cnh'),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // ── Apólices ativas ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Apólices ativas',
                  action: TextButton.icon(
                    onPressed: () =>
                        context.push('/personal-documents/insurances/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nova apólice'),
                  ),
                ),
              ),
              vehiclesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: _DocsSectionSkeleton(cardCount: 2),
                ),
                error: (_, st) => const SliverToBoxAdapter(
                  child: _ErrorCard(message: 'Erro ao carregar apólices.'),
                ),
                data: (vehicles) => _InsurancesSliver(vehicles: vehicles),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // ── Multas pendentes ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Multas pendentes',
                  action: TextButton.icon(
                    onPressed: () =>
                        context.push('/personal-documents/fines/new'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Nova multa'),
                  ),
                ),
              ),
              vehiclesAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: _DocsSectionSkeleton(cardCount: 2),
                ),
                error: (_, st) => const SliverToBoxAdapter(
                  child: _ErrorCard(message: 'Erro ao carregar multas.'),
                ),
                data: (vehicles) => _FinesSliver(vehicles: vehicles),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.huge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sugerir lembretes
  // -------------------------------------------------------------------------

  Future<void> _suggestReminders(BuildContext context) async {
    // Capture context-dependent objects before first await.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sheetBg = context.surfaceRaised;

    final userId = ref.read(currentUserIdProvider);
    final profileRepo = ref.read(userProfileRepositoryProvider);
    final fineRepo = ref.read(fineRepositoryProvider);
    final insuranceRepo = ref.read(insuranceRepositoryProvider);
    final vehicleRepo = ref.read(vehicleRepositoryProvider);
    final reminderRepo = ref.read(reminderRepositoryProvider);

    final now = DateTime.now();

    final UserProfile? profile;
    final List<Vehicle> vehicles;
    final allFines = <Fine>[];
    final allInsurances = <Insurance>[];
    final allReminders = <Reminder>[];

    try {
      // Busca dados necessários.
      profile = await profileRepo.getById(userId);
      vehicles = await vehicleRepo.listByUser(userId);

      for (final v in vehicles) {
        final fines = await fineRepo.listByVehicle(v.id);
        allFines.addAll(fines.where((f) => !f.paid));

        final insurances = await insuranceRepo.listByVehicle(v.id);
        allInsurances.addAll(
          insurances.where((i) => i.deletedAt == null && i.endsAt.isAfter(now)),
        );

        final reminders = await reminderRepo.listByVehicle(v.id);
        allReminders.addAll(reminders);
      }
    } catch (_) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar seus dados. Tente novamente.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final proposals = suggestDocumentReminders(
      profile: profile,
      unpaidFines: allFines,
      activeInsurances: allInsurances,
      now: now,
    );

    final deduped = dedupeProposed(proposals, allReminders);

    if (!mounted) return;

    if (deduped.isEmpty) {
      // Quando o usuário não tem CNH / apólice / multa cadastradas, a
      // sugestão fica vazia "naturalmente" — mostramos uma mensagem
      // orientadora em vez do snackbar genérico (UX 19/06).
      final hasAnyDoc =
          profile?.cnhExpiresAt != null ||
          allInsurances.isNotEmpty ||
          allFines.isNotEmpty;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            hasAnyDoc
                ? 'Nenhum lembrete novo para sugerir no momento.'
                : 'Cadastre uma CNH, apólice ou multa pra eu sugerir lembretes.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: navigator.context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.rLg),
      ),
      builder: (_) => _SuggestRemindersSheet(
        proposals: deduped,
        vehicles: vehicles,
        reminderRepo: reminderRepo,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets auxiliares
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.inkMuted,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: AppRadius.allMd,
      ),
      child: Text(message, style: const TextStyle(color: AppColors.danger)),
    );
  }
}

// ── Skeleton de seção de documentos ──────────────────────────────────────────

/// Skeleton para uma seção de documentos: [cardCount] cards com ícone + 2 linhas.
class _DocsSectionSkeleton extends StatelessWidget {
  const _DocsSectionSkeleton({this.cardCount = 2});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (int i = 0; i < cardCount; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            const SkeletonListCard(),
          ],
        ],
      ),
    );
  }
}

// ── CNH Card ─────────────────────────────────────────────────────────────────

class _CnhCard extends StatelessWidget {
  const _CnhCard({required this.profile, required this.onEdit});

  final UserProfile? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (profile == null ||
        (profile!.cnhNumber == null &&
            profile!.cnhCategory == null &&
            profile!.cnhExpiresAt == null)) {
      // Empty state
      return _EmptyCard(
        message: 'Cadastrar CNH',
        icon: Icons.badge_outlined,
        onTap: onEdit,
      );
    }

    final p = profile!;
    final expiresStr = p.cnhExpiresAt != null
        ? DateFormat('dd/MM/yyyy').format(p.cnhExpiresAt!)
        : null;

    // Verifica se está perto de vencer (30 dias)
    final isExpiringSoon =
        p.cnhExpiresAt != null &&
        p.cnhExpiresAt!.difference(DateTime.now()).inDays <= 30;

    return Semantics(
      button: true,
      label: 'Editar CNH',
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.surfaceRaised,
            borderRadius: AppRadius.allMd,
            border: Border.all(
              color: isExpiringSoon ? AppColors.warning : context.hairline,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isExpiringSoon
                      ? AppColors.warningSoft
                      : context.surfaceSunken,
                  borderRadius: AppRadius.allSm,
                ),
                child: Icon(
                  Icons.badge_outlined,
                  size: 24,
                  color: isExpiringSoon ? AppColors.warning : context.inkMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.cnhNumber != null)
                      Text(
                        'CNH ${p.cnhNumber}',
                        style: AppTypography.body(
                          15,
                          weight: FontWeight.w600,
                          color: context.ink,
                        ),
                      ),
                    if (p.cnhCategory != null)
                      Text(
                        'Categoria ${p.cnhCategory}',
                        style: AppTypography.body(13, color: context.inkMuted),
                      ),
                    if (expiresStr != null) ...[
                      Text(
                        'Vence: $expiresStr',
                        style: AppTypography.body(
                          13,
                          color: isExpiringSoon
                              ? AppColors.warning
                              : context.inkMuted,
                          weight: isExpiringSoon
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (isExpiringSoon)
                        Text(
                          'Vencimento próximo!',
                          style: AppTypography.body(
                            12,
                            color: AppColors.warning,
                            weight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.inkSoft,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty card ────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.message,
    required this.icon,
    required this.onTap,
  });

  final String message;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.surfaceRaised,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: context.hairline, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: context.inkSoft),
            const SizedBox(width: AppSpacing.md),
            Text(
              message,
              // inkMuted (não inkSoft) pra passar WCAG AA em body 15.
              style: AppTypography.body(15, color: context.inkMuted),
            ),
            const Spacer(),
            Icon(Icons.add_rounded, color: context.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Insurances sliver ─────────────────────────────────────────────────────────

class _InsurancesSliver extends ConsumerWidget {
  const _InsurancesSliver({required this.vehicles});

  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AsyncAllInsurancesSliver(vehicles: vehicles);
  }
}

class _AsyncAllInsurancesSliver extends ConsumerStatefulWidget {
  const _AsyncAllInsurancesSliver({required this.vehicles});

  final List<Vehicle> vehicles;

  @override
  ConsumerState<_AsyncAllInsurancesSliver> createState() =>
      _AsyncAllInsurancesSliverState();
}

class _AsyncAllInsurancesSliverState
    extends ConsumerState<_AsyncAllInsurancesSliver> {
  List<(Insurance, String)>? _items; // (insurance, vehicleNickname)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(insuranceRepositoryProvider);
    final now = DateTime.now();
    final items = <(Insurance, String)>[];
    for (final v in widget.vehicles) {
      final list = await repo.listByVehicle(v.id);
      for (final i in list) {
        if (i.endsAt.isAfter(now)) {
          items.add((i, v.nickname));
        }
      }
    }
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null) {
      return const SliverToBoxAdapter(
        child: _DocsSectionSkeleton(cardCount: 2),
      );
    }

    if (_items!.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(
            'Nenhuma apólice ativa.',
            style: AppTypography.body(14, color: context.inkMuted),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: _items!.length,
      separatorBuilder: (_, idx) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final (insurance, nickname) = _items![i];
        return _InsuranceCard(
          insurance: insurance,
          vehicleNickname: nickname,
          onTap: () =>
              context.push('/personal-documents/insurances/${insurance.id}'),
        );
      },
    );
  }
}

class _InsuranceCard extends StatelessWidget {
  const _InsuranceCard({
    required this.insurance,
    required this.vehicleNickname,
    required this.onTap,
  });

  final Insurance insurance;
  final String vehicleNickname;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final daysLeft = insurance.endsAt.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft <= 60;
    final endStr = DateFormat('dd/MM/yyyy').format(insurance.endsAt);

    return Semantics(
      button: true,
      label: 'Editar apólice $vehicleNickname',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.surfaceRaised,
            borderRadius: AppRadius.allMd,
            border: Border.all(
              color: isExpiringSoon ? AppColors.warning : context.hairline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 24,
                color: isExpiringSoon ? AppColors.warning : context.inkMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insurance.insurer ?? 'Seguro',
                      style: AppTypography.body(
                        14,
                        weight: FontWeight.w600,
                        color: context.ink,
                      ),
                    ),
                    Text(
                      '$vehicleNickname · vence $endStr',
                      style: AppTypography.body(12, color: context.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.inkSoft,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fines sliver ─────────────────────────────────────────────────────────────

class _FinesSliver extends ConsumerStatefulWidget {
  const _FinesSliver({required this.vehicles});

  final List<Vehicle> vehicles;

  @override
  ConsumerState<_FinesSliver> createState() => _FinesSliverState();
}

class _FinesSliverState extends ConsumerState<_FinesSliver> {
  List<(Fine, String)>? _items; // (fine, vehicleNickname)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(fineRepositoryProvider);
    final items = <(Fine, String)>[];
    for (final v in widget.vehicles) {
      final list = await repo.listByVehicle(v.id);
      for (final f in list) {
        if (!f.paid) items.add((f, v.nickname));
      }
    }
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null) {
      return const SliverToBoxAdapter(
        child: _DocsSectionSkeleton(cardCount: 2),
      );
    }

    if (_items!.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Text(
            'Sem multas — bom motorista!',
            style: AppTypography.body(14, color: AppColors.success),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: _items!.length,
      separatorBuilder: (_, idx) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final (fine, nickname) = _items![i];
        return _FineCard(
          fine: fine,
          vehicleNickname: nickname,
          onTap: () => context.push('/personal-documents/fines/${fine.id}'),
        );
      },
    );
  }
}

class _FineCard extends StatelessWidget {
  const _FineCard({
    required this.fine,
    required this.vehicleNickname,
    required this.onTap,
  });

  final Fine fine;
  final String vehicleNickname;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dueStr = fine.dueDate != null
        ? 'Prazo: ${DateFormat('dd/MM/yyyy').format(fine.dueDate!)}'
        : null;
    final isUrgent =
        fine.dueDate != null &&
        fine.dueDate!.difference(DateTime.now()).inDays <= 7;

    return Semantics(
      button: true,
      label: 'Editar multa $vehicleNickname',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.surfaceRaised,
            borderRadius: AppRadius.allMd,
            border: Border.all(
              color: isUrgent ? AppColors.danger : context.hairline,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 24,
                color: isUrgent ? AppColors.danger : AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fine.description,
                      style: AppTypography.body(
                        14,
                        weight: FontWeight.w600,
                        color: context.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$vehicleNickname · R\$ ${fine.amount}',
                      style: AppTypography.body(12, color: context.inkMuted),
                    ),
                    if (dueStr != null)
                      Text(
                        dueStr,
                        style: AppTypography.body(
                          12,
                          color: isUrgent ? AppColors.danger : context.inkMuted,
                          weight: isUrgent ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.inkSoft,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sheet de sugestões de lembretes ──────────────────────────────────────────

class _SuggestRemindersSheet extends ConsumerStatefulWidget {
  const _SuggestRemindersSheet({
    required this.proposals,
    required this.vehicles,
    required this.reminderRepo,
  });

  final List<ProposedReminder> proposals;
  final List<Vehicle> vehicles;
  final dynamic reminderRepo; // ReminderRepository

  @override
  ConsumerState<_SuggestRemindersSheet> createState() =>
      _SuggestRemindersSheetState();
}

class _SuggestRemindersSheetState
    extends ConsumerState<_SuggestRemindersSheet> {
  late List<ProposedReminder> _visible;

  @override
  void initState() {
    super.initState();
    _visible = List.of(widget.proposals);
  }

  Future<void> _create(ProposedReminder p) async {
    setState(() => _visible.remove(p));

    // Usa o primeiro veículo como default para lembretes de documentos.
    final vehicleId = widget.vehicles.isNotEmpty
        ? widget.vehicles.first.id
        : '';
    if (vehicleId.isEmpty) return;

    final now = DateTime.now().toUtc();
    final reminder = Reminder(
      id: const Uuid().v4(),
      vehicleId: vehicleId,
      type: ReminderType.porData,
      title: p.title,
      dueDate: p.dueDate,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${p.title}" adicionado aos lembretes.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _visible.add(p));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível criar o lembrete.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _ignore(ProposedReminder p) => setState(() => _visible.remove(p));

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.hairline,
                borderRadius: AppRadius.allSm,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Text(
              _visible.isEmpty
                  ? 'Todos os lembretes criados!'
                  : 'Sugestões de lembretes',
              style: AppTypography.body(
                17,
                weight: FontWeight.w700,
                color: context.ink,
              ),
            ),
          ),
          Expanded(
            child: _visible.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: AppColors.success,
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.huge,
                    ),
                    itemCount: _visible.length,
                    separatorBuilder: (_, idx) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final p = _visible[i];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.surfaceRaised,
                          borderRadius: AppRadius.allMd,
                          border: Border.all(color: context.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.title,
                              style: AppTypography.body(
                                14,
                                weight: FontWeight.w600,
                                color: context.ink,
                              ),
                            ),
                            if (p.rationale.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                p.rationale,
                                style: AppTypography.body(
                                  12,
                                  color: context.inkMuted,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _create(p),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        40,
                                      ),
                                      backgroundColor: AppColors.brand,
                                      foregroundColor: AppColors.brandInk,
                                    ),
                                    child: const Text('Criar'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _ignore(p),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        40,
                                      ),
                                      side: BorderSide(color: context.hairline),
                                      foregroundColor: context.inkMuted,
                                    ),
                                    child: const Text('Ignorar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
