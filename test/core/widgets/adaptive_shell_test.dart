// Testes de widget para AdaptiveShell.
//
// Cobre:
//   1. Viewport <1024px: renderiza apenas o child, sem NavigationRail.
//   2. Viewport >=1024px: renderiza NavigationRail + child.
//   3. Em desktop: 3 destinos globais presentes (Garagem, Documentos, Settings).
//   4. Em desktop com veículo ativo mockado: exibe nome + placa + sub-itens.
//   5. Tap em "Garagem" navega para /vehicles.

import 'package:autolog/core/widgets/adaptive_shell.dart';
import 'package:autolog/domain/models/enums.dart';
import 'package:autolog/domain/models/vehicle.dart';
import 'package:autolog/features/vehicles/providers/active_vehicle_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Monta o AdaptiveShell dentro de MaterialApp + GoRouter mínimo.
///
/// [location] é passado diretamente para AdaptiveShell (não depende de
/// GoRouterState dentro do widget, então funciona em testes simples).
Widget buildTestApp({
  required Size size,
  required Widget shell,
  List<Override> overrides = const [],
  GoRouter? router,
}) {
  final goRouter =
      router ??
      GoRouter(
        initialLocation: '/vehicles',
        routes: [
          GoRoute(
            path: '/vehicles',
            builder: (ctx, s) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/personal-documents',
            builder: (ctx, s) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/settings',
            builder: (ctx, s) => const SizedBox.shrink(),
          ),
        ],
      );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: goRouter,
      builder: (context, routerChild) {
        return SizedBox(
          width: size.width,
          height: size.height,
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: shell,
          ),
        );
      },
    ),
  );
}

Vehicle fakeVehicle() => Vehicle(
  id: 'abc',
  userId: 'user-1',
  nickname: 'Civic',
  plate: 'ABC1D23',
  fuelType: FuelType.flex,
  initialOdometer: 0,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  syncStatus: SyncStatus.synced,
);

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  group('AdaptiveShell', () {
    testWidgets(
      '1. Viewport mobile (600x800): renderiza só o child, sem NavigationRail',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(600, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const childKey = Key('child_placeholder');
        await tester.pumpWidget(
          buildTestApp(
            size: const Size(600, 800),
            shell: const AdaptiveShell(
              location: '/vehicles',
              child: Placeholder(key: childKey),
            ),
          ),
        );

        expect(find.byKey(childKey), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      },
    );

    testWidgets(
      '2. Viewport desktop (1280x800): renderiza rail (Garagem visível) + child',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const childKey = Key('child_placeholder');
        await tester.pumpWidget(
          buildTestApp(
            size: const Size(1280, 800),
            shell: const AdaptiveShell(
              location: '/vehicles',
              child: Placeholder(key: childKey),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(childKey), findsOneWidget);
        // Rail é implementado como itens customizados — verifica pelo label.
        expect(find.text('Garagem'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Desktop: itens globais Garagem, Documentos e Settings presentes',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildTestApp(
            size: const Size(1280, 800),
            shell: const AdaptiveShell(
              location: '/vehicles',
              child: Placeholder(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Garagem'), findsOneWidget);
        expect(find.text('Documentos'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Desktop + veículo ativo mockado: exibe nickname, placa e sub-itens',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final vehicle = fakeVehicle();

        await tester.pumpWidget(
          buildTestApp(
            size: const Size(1280, 800),
            overrides: [
              activeVehicleIdProvider.overrideWith(
                (ref) => FakeActiveVehicleNotifier('abc'),
              ),
              activeVehicleProvider.overrideWith(
                (ref) => Future.value(vehicle),
              ),
            ],
            shell: const AdaptiveShell(
              location: '/vehicles/abc',
              child: Placeholder(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Nickname em uppercase.
        expect(find.textContaining('CIVIC', findRichText: true), findsWidgets);
        expect(
          find.textContaining('ABC1D23', findRichText: true),
          findsWidgets,
        );

        // Sub-itens do veículo.
        expect(find.text('Detalhe'), findsOneWidget);
        expect(find.text('Despesas'), findsOneWidget);
        expect(find.text('Lembretes'), findsOneWidget);
        expect(find.text('Relatórios'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Tap em "Garagem" — AdaptiveShell está no contexto do GoRouter',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final router = GoRouter(
          initialLocation: '/personal-documents',
          routes: [
            GoRoute(
              path: '/vehicles',
              builder: (ctx, s) => const SizedBox.shrink(),
            ),
            GoRoute(
              path: '/personal-documents',
              builder: (ctx, s) => const AdaptiveShell(
                location: '/personal-documents',
                child: SizedBox.shrink(),
              ),
            ),
            GoRoute(
              path: '/settings',
              builder: (ctx, s) => const SizedBox.shrink(),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: router)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Garagem'));
        await tester.pumpAndSettle();

        // Após tap, deve estar na rota /vehicles.
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/vehicles',
        );
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Notifier fake que ignora SharedPreferences e carrega estado fixo.
class FakeActiveVehicleNotifier extends ActiveVehicleNotifier {
  FakeActiveVehicleNotifier(this.fixedId);

  final String? fixedId;

  @override
  Future<void> loadInitial() async {
    state = fixedId;
  }
}
