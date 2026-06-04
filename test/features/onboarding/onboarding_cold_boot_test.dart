// Teste de regressão homologação 04/06/2026 (re-homolog #2)
//
// Bug: redirect lia FutureProvider.valueOrNull em cold boot — o future ainda
// não tinha resolvido → null → caia no auth gate → /login sem mostrar onboarding.
//
// Fix: SharedPreferences pré-carregado no main() via override síncrono;
// onboardingNeededProvider vira Provider<bool> síncrono.

import 'package:autolog/features/onboarding/onboarding_providers.dart';
import 'package:autolog/features/onboarding/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('regressão cold boot — onboardingNeededProvider síncrono', () {
    test(
      'regressão homolog 04/06 #2: cold boot com prefs vazio retorna needed=true '
      'SINCRONAMENTE (sem awaitar future)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // authServiceProvider não está disponível em teste unitário puro;
            // usamos um override do authIsLoggedInProvider com false.
            authIsLoggedInProvider.overrideWithValue(false),
          ],
        );
        addTearDown(container.dispose);

        // Lê SINCRONAMENTE — não awaita future.
        final needed = container.read(onboardingNeededProvider);

        expect(
          needed,
          isTrue,
          reason:
              'em cold boot deslogado, sem ter visto, DEVE mostrar onboarding '
              'sem awaitar nada',
        );
      },
    );

    test('cold boot com onboarding_seen=true → false', () async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authIsLoggedInProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final needed = container.read(onboardingNeededProvider);
      expect(needed, isFalse, reason: 'já viu → não mostra');
    });

    test('cold boot logado → false (não vê marketing)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authIsLoggedInProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      final needed = container.read(onboardingNeededProvider);
      expect(needed, isFalse, reason: 'logado → não mostra onboarding de marketing');
    });

    test('cold boot já viu E logado → false', () async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authIsLoggedInProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      final needed = container.read(onboardingNeededProvider);
      expect(needed, isFalse);
    });

    test(
      'regressão homolog 04/06 #3: após markSeen + invalidate, '
      'provider retorna false (sem loop no redirect)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authIsLoggedInProvider.overrideWithValue(false),
          ],
        );
        addTearDown(container.dispose);

        // Estado inicial: precisa de onboarding.
        expect(container.read(onboardingNeededProvider), isTrue);

        // User clicou em "Criar conta" / "Já tenho conta" → markSeen.
        await container.read(onboardingRepositoryProvider).markSeen();

        // Sem invalidate, o cache do Provider mantém o valor antigo —
        // redirect manda de volta pra /onboarding → loop.
        container.invalidate(onboardingNeededProvider);

        // Após invalidate, lê valor novo do SharedPrefs → false.
        expect(container.read(onboardingNeededProvider), isFalse);
      },
    );
  });
}
