// Shell adaptativo — exibe NavigationRail em viewports ≥1024px.
//
// Em <1024px devolve o child diretamente (comportamento mobile preservado).
// Em ≥1024px monta Scaffold com Row: [_RailContent | divider | child].
//
// Uso: injetado via MaterialApp.router(builder:) em app.dart.
// A location é passada como parâmetro porque o builder: do MaterialApp.router
// não está dentro da sub-árvore de um RouteBase.builder; passar explicitamente
// é mais testável e evita dependência de contexto do GoRouter.

import 'package:autolog/core/design/dynamic_colors.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/core/design/typography.dart';
import 'package:autolog/core/widgets/app_logo.dart' show AppLogo, AppLogoTheme;
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/vehicles/providers/active_vehicle_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Breakpoint
// ---------------------------------------------------------------------------

const _kDesktopBreakpoint = 1024.0;

// ---------------------------------------------------------------------------
// AdaptiveShell
// ---------------------------------------------------------------------------

/// Widget que envolve qualquer tela do app e, em desktop (≥1024px),
/// injeta a [NavigationRail] persistente à esquerda.
///
/// [location] = rota atual (ex: `/vehicles/abc/expenses`). Passado
/// explicitamente para facilitar testes e evitar dependência de contexto
/// do GoRouter.
///
/// Em mobile/tablet (<1024px) retorna [child] sem modificação.
class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({
    super.key,
    this.location = '/vehicles',
    required this.child,
  });

  final Widget child;

  /// Rota atual — usada para highlighting dos itens do rail.
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _kDesktopBreakpoint) {
          return child;
        }

        return Scaffold(
          backgroundColor: context.surface,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RailContent(location: location),
              VerticalDivider(width: 1, thickness: 1, color: context.hairline),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _RailContent — conteúdo completo do rail (240 px)
// ---------------------------------------------------------------------------

class _RailContent extends ConsumerWidget {
  const _RailContent({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVehicleAsync = ref.watch(activeVehicleProvider);
    final activeVehicle = activeVehicleAsync.valueOrNull;

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Logo ──────────────────────────────────────────────────────────
          // Em dark mode usamos a variante `light` (wordmark claro sobre
          // surface escuro). Em light mode, a default `dark` (wordmark
          // escuro sobre surface claro). Sem isso o wordmark fica
          // invisível em dark.
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: AppLogo(
                size: 22,
                showGlyph: true,
                logoTheme: context.isDark
                    ? AppLogoTheme.light
                    : AppLogoTheme.dark,
              ),
            ),
          ),

          // ── Itens globais ─────────────────────────────────────────────────
          _RailNavItem(
            label: 'Garagem',
            icon: Icons.directions_car_outlined,
            selectedIcon: Icons.directions_car,
            route: '/vehicles',
            location: location,
            isActive:
                location == '/vehicles' || location.startsWith('/vehicles/new'),
          ),
          _RailNavItem(
            label: 'Documentos',
            icon: Icons.folder_outlined,
            selectedIcon: Icons.folder,
            route: '/personal-documents',
            location: location,
            isActive: location.startsWith('/personal-documents'),
          ),

          // ── Bloco contextual do veículo ──────────────────────────────────
          if (activeVehicle != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Divider(height: 1, color: context.hairline),
            ),
            const SizedBox(height: AppSpacing.sm),
            _VehicleBlock(vehicle: activeVehicle, location: location),
          ],

          const Spacer(),

          // ── Settings no rodapé ───────────────────────────────────────────
          _RailNavItem(
            label: 'Configurações',
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            route: '/settings',
            location: location,
            isActive: location.startsWith('/settings'),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RailNavItem — item de navegação genérico (global + footer)
// ---------------------------------------------------------------------------

class _RailNavItem extends StatelessWidget {
  const _RailNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.location,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final String location;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    // Cor do destaque do item selecionado: `context.ink` (= onSurface) tem
    // contraste garantido tanto em light quanto em dark. Antes usávamos
    // colorScheme.primary, mas em dark mode primary é a cor brand-escura,
    // que some no fundo escuro.
    final bg = isActive
        ? context.ink.withValues(alpha: 0.08)
        : Colors.transparent;
    final fg = isActive ? context.ink : context.inkMuted;

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(isActive ? selectedIcon : icon, size: 20, color: fg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body(14, color: fg),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VehicleBlock — bloco contextual do veículo ativo
// ---------------------------------------------------------------------------

class _VehicleBlock extends StatelessWidget {
  const _VehicleBlock({required this.vehicle, required this.location});

  final Vehicle vehicle;
  final String location;

  @override
  Widget build(BuildContext context) {
    final id = vehicle.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho: nickname + placa
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.nickname.toUpperCase(),
                style: AppTypography.body(
                  11,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: context.inkMuted,
                ),
              ),
              if (vehicle.plate != null)
                Text(
                  vehicle.plate!.toUpperCase(),
                  style: AppTypography.body(11, color: context.inkMuted),
                ),
            ],
          ),
        ),

        // Sub-itens
        _VehicleNavItem(
          label: 'Detalhe',
          icon: Icons.info_outline,
          route: '/vehicles/$id',
          location: location,
          exact: true,
        ),
        _VehicleNavItem(
          label: 'Despesas',
          icon: Icons.receipt_long_outlined,
          route: '/vehicles/$id/expenses',
          location: location,
        ),
        _VehicleNavItem(
          label: 'Lembretes',
          icon: Icons.notifications_outlined,
          route: '/vehicles/$id/reminders',
          location: location,
        ),
        _VehicleNavItem(
          label: 'Relatórios',
          icon: Icons.bar_chart_outlined,
          route: '/vehicles/$id/reports',
          location: location,
        ),

        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _VehicleNavItem — sub-item do bloco contextual
// ---------------------------------------------------------------------------

class _VehicleNavItem extends StatelessWidget {
  const _VehicleNavItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.location,
    this.exact = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final String location;

  /// Se true, match só na rota exata (não em sub-rotas). Usado em "Detalhe"
  /// porque `/vehicles/:id` é prefixo de `/vehicles/:id/expenses` etc., e
  /// sem isso o "Detalhe" ficaria sempre selecionado junto.
  final bool exact;

  bool get _isActive => exact
      ? location == route
      : location == route || location.startsWith('$route/');

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive;
    // Cor do destaque do item selecionado: `context.ink` (= onSurface) tem
    // contraste garantido tanto em light quanto em dark. Antes usávamos
    // colorScheme.primary, mas em dark mode primary é a cor brand-escura,
    // que some no fundo escuro.
    final bg = isActive
        ? context.ink.withValues(alpha: 0.08)
        : Colors.transparent;
    final fg = isActive ? context.ink : context.inkMuted;

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.body(13, color: fg)),
          ],
        ),
      ),
    );
  }
}
