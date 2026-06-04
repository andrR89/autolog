import 'package:autolog/features/onboarding/onboarding_repository.dart';
import 'package:autolog/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
        path: '/login',
        builder: (context, _) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, _) => const Scaffold(body: Text('Signup')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      // Usa repositório em memória — sem SharedPreferences real no teste.
      onboardingRepositoryProvider.overrideWithValue(
        InMemoryOnboardingRepository(),
      ),
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

    testWidgets(
      'último slide exibe "Criar conta" e "Já tenho conta" em vez de "Próximo"',
      (tester) async {
        await tester.pumpWidget(_buildOnboarding());
        await tester.pumpAndSettle();

        // Avança até o último slide
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('Próximo'));
          await tester.pumpAndSettle();
        }

        expect(find.text('Criar conta'), findsOneWidget);
        expect(find.text('Já tenho conta'), findsOneWidget);
        expect(find.text('Próximo'), findsNothing);
      },
    );

    testWidgets('"Criar conta" navega para /signup', (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // Avança até o último slide
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Signup'), findsOneWidget);
    });

    testWidgets('"Já tenho conta" navega para /login', (tester) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // Avança até o último slide
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Próximo'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Já tenho conta'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('"Pular" aparece nos slides 1-3 e navega para /login', (
      tester,
    ) async {
      await tester.pumpWidget(_buildOnboarding());
      await tester.pumpAndSettle();

      // Slide 1: "Pular" deve estar visível
      expect(find.text('Pular'), findsOneWidget);

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
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
