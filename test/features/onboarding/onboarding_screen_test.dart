import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/onboarding/onboarding_screen.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Stub do repositório para evitar Drift em memória neste widget test.
// ---------------------------------------------------------------------------

class _FakeUserSettingsRepo implements UserSettingsRepository {
  bool _onboardingSeen = false;

  @override
  Future<bool> getOnboardingSeen(String userId) async => _onboardingSeen;

  @override
  Future<void> setOnboardingSeen(String userId) async {
    _onboardingSeen = true;
  }

  @override
  Future<ThemeModeEnum> getThemeMode(String userId) async =>
      ThemeModeEnum.system;

  @override
  Future<void> setThemeMode(String userId, ThemeModeEnum mode) async {}

  @override
  Stream<ThemeModeEnum> watchThemeMode(String userId) =>
      Stream.value(ThemeModeEnum.system);

  @override
  Future<NotificationPreferences> getNotifPrefs(String userId) async =>
      const NotificationPreferences();

  @override
  Future<void> setNotifPref(
    String userId,
    String category,
    bool enabled,
  ) async {}

  @override
  Stream<NotificationPreferences> watchNotifPrefs(String userId) =>
      Stream.value(const NotificationPreferences());
}

// ---------------------------------------------------------------------------
// Helper de montagem
// ---------------------------------------------------------------------------

Widget _buildOnboarding() {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, _) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('test-user'),
      userSettingsRepositoryProvider.overrideWithValue(_FakeUserSettingsRepo()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// ---------------------------------------------------------------------------
// Testes
// ---------------------------------------------------------------------------

void main() {
  group('OnboardingScreen', () {
    testWidgets('exibe o primeiro slide ao abrir', (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo ao AutoLog'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);
    });

    testWidgets('"Próximo" avança para o segundo slide', (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      expect(find.text('Registre rápido'), findsOneWidget);
    });

    testWidgets('navega pelos 4 slides com "Próximo"', (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // Slide 1 → 2
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Registre rápido'), findsOneWidget);

      // Slide 2 → 3
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Veja o que importa'), findsOneWidget);

      // Slide 3 → 4
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      expect(find.text('Nunca esqueça'), findsOneWidget);
    });

    testWidgets('último slide exibe "Começar" em vez de "Próximo"',
        (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // Avança até o último slide
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Começar'), findsOneWidget);
      expect(find.text('Próximo'), findsNothing);
    });

    testWidgets('"Começar" navega para home', (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // Avança até o último slide
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Começar'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('"Pular" aparece nos slides 1-3 e navega para home',
        (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // Slide 1: "Pular" deve estar visível
      expect(find.text('Pular'), findsOneWidget);

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('"Pular" não aparece no último slide', (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // Avança até o último slide
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Pular'), findsNothing);
    });

    testWidgets('indicador de dots tem 4 dots', (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // _DotsIndicator produz 4 AnimatedContainers
      final containers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(containers.length, 4);
    });
  });
}
