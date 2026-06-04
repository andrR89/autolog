import 'package:autolog/features/onboarding/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ── InMemoryOnboardingRepository ──────────────────────────────────────────

  group('InMemoryOnboardingRepository', () {
    late InMemoryOnboardingRepository repo;

    setUp(() {
      repo = InMemoryOnboardingRepository();
    });

    test('padrão é false — não viu onboarding', () {
      expect(repo.hasSeenOnboarding(), isFalse);
    });

    test('markSeen → hasSeenOnboarding retorna true', () async {
      await repo.markSeen();
      expect(repo.hasSeenOnboarding(), isTrue);
    });

    test('markSeen é idempotente — chamar duas vezes mantém true', () async {
      await repo.markSeen();
      await repo.markSeen();
      expect(repo.hasSeenOnboarding(), isTrue);
    });
  });

  // ── SharedPrefsOnboardingRepository ──────────────────────────────────────

  group('SharedPrefsOnboardingRepository', () {
    late SharedPrefsOnboardingRepository repo;
    late SharedPreferences prefs;

    setUp(() async {
      // Mock de SharedPreferences sem estado prévio.
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = SharedPrefsOnboardingRepository(prefs);
    });

    test('padrão é false sem valor prévio', () {
      expect(repo.hasSeenOnboarding(), isFalse);
    });

    test('markSeen → hasSeenOnboarding retorna true', () async {
      await repo.markSeen();
      expect(repo.hasSeenOnboarding(), isTrue);
    });

    test('markSeen é idempotente', () async {
      await repo.markSeen();
      await repo.markSeen();
      expect(repo.hasSeenOnboarding(), isTrue);
    });

    test('persiste entre chamadas distintas ao getInstance', () async {
      // Simula reinicialização do singleton sem limpar prefs.
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final prefs2 = await SharedPreferences.getInstance();
      final repo2 = SharedPrefsOnboardingRepository(prefs2);
      expect(repo2.hasSeenOnboarding(), isTrue);
    });
  });

  // ── sharedPreferencesProvider ─────────────────────────────────────────────

  group('sharedPreferencesProvider', () {
    test('lança UnimplementedError sem override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(sharedPreferencesProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('retorna instância quando overridden', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(sharedPreferencesProvider), same(prefs));
    });
  });
}
