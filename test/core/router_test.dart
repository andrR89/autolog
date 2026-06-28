// Testes estáticos da estrutura de appRoutes.
//
// Valida que:
//   1. Rotas de auth flow (/login, /signup, /onboarding, /paywall) estão
//      fora da ShellRoute — ou seja, são GoRoutes top-level sem AdaptiveShell.
//   2. Rotas pós-auth (/vehicles, /settings, /personal-documents, etc.) estão
//      dentro de uma ShellRoute.
//
// Esses testes são de análise estrutural do grafo de rotas, sem runtime do
// Flutter. Não testam navegação — para isso há os widget_test e adaptive_shell_test.

import 'package:autolog/core/router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('appRoutes — estrutura da ShellRoute', () {
    // Rotas top-level que NÃO devem estar dentro de ShellRoute.
    const unshelledPaths = ['/login', '/signup', '/onboarding', '/paywall'];

    // Rotas que DEVEM estar dentro de ShellRoute.
    const shelledPaths = [
      '/vehicles',
      '/vehicles/new',
      '/personal-documents',
      '/settings',
      '/stations',
      '/recap',
    ];

    /// Retorna todos os [GoRoute] top-level (não aninhados dentro de ShellRoute).
    List<String> topLevelGoPaths(List<RouteBase> routes) {
      return routes.whereType<GoRoute>().map((r) => r.path).toList();
    }

    /// Retorna os paths de GoRoutes que são filhas diretas de ShellRoute(s).
    List<String> shelledGoPaths(List<RouteBase> routes) {
      final result = <String>[];
      for (final route in routes) {
        if (route is ShellRoute) {
          result.addAll(route.routes.whereType<GoRoute>().map((r) => r.path));
        }
      }
      return result;
    }

    test(
      'rotas de auth/onboarding/paywall são top-level (fora de ShellRoute)',
      () {
        final topLevel = topLevelGoPaths(appRoutes);
        for (final path in unshelledPaths) {
          expect(
            topLevel,
            contains(path),
            reason: '$path deveria ser top-level (fora de ShellRoute)',
          );
        }
      },
    );

    test('rotas pós-auth estão dentro de ShellRoute', () {
      final shelled = shelledGoPaths(appRoutes);
      for (final path in shelledPaths) {
        expect(
          shelled,
          contains(path),
          reason: '$path deveria estar dentro de ShellRoute',
        );
      }
    });

    test('rotas de auth/onboarding/paywall NÃO estão dentro de ShellRoute', () {
      final shelled = shelledGoPaths(appRoutes);
      for (final path in unshelledPaths) {
        expect(
          shelled,
          isNot(contains(path)),
          reason: '$path não deveria estar dentro de ShellRoute',
        );
      }
    });

    test('existe exatamente uma ShellRoute em appRoutes', () {
      final shellRoutes = appRoutes.whereType<ShellRoute>().toList();
      expect(shellRoutes, hasLength(1));
    });
  });
}
