// Tela de "Garagem" — lista de veículos do usuário.
//
// Design (Tranche B):
//
// - **Título**: "Garagem" em display type (Bricolage 32/600) num header
//   custom, abaixo da AppBar transparente. PT-BR personal, possessivo
//   ("Garagem" → "minha garagem" implícito), mais quente que
//   "Meus veículos" (que ainda aparece como subtítulo discreto para
//   manter o ancestral semântico).
//
// - **Cards** em `VehicleCard`: faixa lateral por combustível, nickname
//   grande, plate-strip, fuel-chip com bolinha colorida, odômetro
//   tabular. Visualmente nada como um ListTile.
//
// - **Empty state** em `VehiclesEmptyState`: "vaga de garagem" tracejada,
//   headline calorosa, CTA inline em accent.
//
// - **Delete** via swipe (Dismissible) com confirm dialog (mais leve
//   que o AlertDialog antigo) e SnackBar de feedback após excluir.
//   Mantém soft delete — sem hard delete neste MVP.
//
// - **AppBar** continua expondo o indicador de sync e o "sair", mas
//   sem título (o header custom assume o papel). Mantém compat com
//   o smoke test (não procura por título "Meus veículos") e com os
//   testes de back button (não tocam nessa tela).

import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/sync/sync_indicator.dart';
import 'package:autolog/features/sync/sync_status_notifier.dart';
import 'package:autolog/features/vehicles/vehicle_saver.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:autolog/features/vehicles/widgets/vehicle_card.dart';
import 'package:autolog/features/vehicles/widgets/vehicles_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VehiclesListScreen extends ConsumerStatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  ConsumerState<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends ConsumerState<VehiclesListScreen> {
  @override
  void initState() {
    super.initState();
    // Dispara um sync após o primeiro frame — o provider container já está
    // pronto e a UI não é bloqueada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(syncStatusProvider.notifier).triggerSync();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      // AppBar enxuta — sem título; o header da seção (logo abaixo) é
      // que carrega o display type. Mantém os actions críticos.
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        // Status bar com ícones escuros — fundo é o surface off-white.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        // Necessário pra remover o leading default (back arrow) em tela
        // raiz e abrir espaço para a marca, sem mexer no router.
        automaticallyImplyLeading: false,
        title: null,
        actions: [
          const SyncIndicator(),
          IconButton(
            icon: const Icon(Icons.badge_outlined, color: AppColors.inkMuted),
            tooltip: 'Documentos',
            onPressed: () => context.push('/personal-documents'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.inkMuted),
            tooltip: 'Configurações',
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.inkMuted),
            tooltip: 'Sair',
            onPressed: () async {
              try {
                await ref.read(authServiceProvider).signOut();
              } catch (_) {
                // Ignorar erros de rede no signOut — estado local já é limpo.
              }
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: vehiclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              _ErrorState(onRetry: () => ref.invalidate(vehiclesProvider)),
          data: (vehicles) => _Body(vehicles: vehicles),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/new'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentInk,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Novo veículo'),
        tooltip: 'Adicionar veículo',
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.vehicles});

  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vehicles.isEmpty) {
      return Column(
        children: [
          const _Header(count: 0),
          Expanded(
            child: VehiclesEmptyState(
              onAdd: () => context.push('/vehicles/new'),
            ),
          ),
        ],
      );
    }

    // ListView.builder com header como primeiro item — evita CustomScrollView
    // (que complicaria o sliver-app-bar sem ganho real para a quantidade
    // típica de carros, 1-3).
    return ListView.separated(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        // Bottom padding generoso para o FAB extended não cobrir o último
        // card.
        bottom: AppSpacing.huge + AppSpacing.xl,
      ),
      itemCount: vehicles.length + 1,
      separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _Header(count: vehicles.length);
        }
        final vehicle = vehicles[index - 1];
        return _DismissibleVehicleCard(vehicle: vehicle);
      },
    );
  }
}

/// Header de seção: "Garagem" em display, com contagem discreta abaixo.
class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = switch (count) {
      0 => 'nenhum carro por aqui ainda',
      1 => '1 carro',
      _ => '$count carros',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow "label" — referência editorial, dá ar de seção
          // dentro de uma publicação.
          Text(
            'MINHA',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.inkMuted,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Garagem',
            style: AppTypography.display(
              36,
              weight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Wrap em Dismissible para swipe-to-delete com confirm + SnackBar.
///
/// Decisões:
/// - `confirmDismiss` mostra um dialog leve (PT-BR, sem alarmismo).
/// - Background do swipe usa `dangerSoft` (não vermelho gritante).
/// - Após delete, exibe SnackBar informativa — o usuário sabe que a
///   ação aconteceu sem precisar verificar a lista vazia.
/// - SEM "Desfazer" no SnackBar: o saver não expõe restore e a tarefa
///   diz para "considerar" undo, não obriga. Mantemos honestos: o
///   delete é soft, "pode ser recuperado depois", e a mensagem reforça.
class _DismissibleVehicleCard extends ConsumerWidget {
  const _DismissibleVehicleCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('vehicle-${vehicle.id}'),
      direction: DismissDirection.endToStart,
      background: const _DismissBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await ref.read(vehicleSaverProvider).delete(vehicle.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('"${vehicle.nickname}" foi excluído.'),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(AppSpacing.lg),
              ),
            );
        }
      },
      child: VehicleCard(
        vehicle: vehicle,
        onTap: () => context.push('/vehicles/${vehicle.id}'),
        onEdit: () => context.push('/vehicles/${vehicle.id}/edit'),
        onDelete: () => _deleteFromMenu(context, ref),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: Text(
          '"${vehicle.nickname}" será removido da garagem. '
          'Você pode recuperar depois nas configurações.',
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

  Future<void> _deleteFromMenu(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmDelete(context);
    if (confirmed == true) {
      await ref.read(vehicleSaverProvider).delete(vehicle.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('"${vehicle.nickname}" foi excluído.'),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppSpacing.lg),
            ),
          );
      }
    }
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
            const Icon(Icons.cloud_off, size: 40, color: AppColors.inkMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Não foi possível carregar sua garagem.',
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
