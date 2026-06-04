import 'package:autolog/features/onboarding/onboarding_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ── InMemoryOnboardingRepository ──────────────────────────────────────────

  group('InMemoryOnboardingRepository', () {
    late InMemoryOnboardingRepository repo;

    setUp(() {
      repo = InMemoryOnboardingRepository();
    });

    test('padrão é false — não viu onboarding', () async {
      expect(await repo.hasSeenOnboarding(), isFalse);
    });

    test('markSeen → hasSeenOnboarding retorna true', () async {
      await repo.markSeen();
      expect(await repo.hasSeenOnboarding(), isTrue);
    });

    test('markSeen é idempotente — chamar duas vezes mantém true', () async {
      await repo.markSeen();
      await repo.markSeen();
      expect(await repo.hasSeenOnboarding(), isTrue);
    });
  });

  // ── SharedPrefsOnboardingRepository ──────────────────────────────────────

  group('SharedPrefsOnboardingRepository', () {
    late SharedPrefsOnboardingRepository repo;

    setUp(() {
      // Mock de SharedPreferences sem estado prévio.
      SharedPreferences.setMockInitialValues({});
      repo = SharedPrefsOnboardingRepository();
    });

    test('padrão é false sem valor prévio', () async {
      expect(await repo.hasSeenOnboarding(), isFalse);
    });

    test('markSeen → hasSeenOnboarding retorna true', () async {
      await repo.markSeen();
      expect(await repo.hasSeenOnboarding(), isTrue);
    });

    test('markSeen é idempotente', () async {
      await repo.markSeen();
      await repo.markSeen();
      expect(await repo.hasSeenOnboarding(), isTrue);
    });

    test('persiste entre chamadas distintas ao getInstance', () async {
      // Simula reinicialização do singleton sem limpar prefs.
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final repo2 = SharedPrefsOnboardingRepository();
      expect(await repo2.hasSeenOnboarding(), isTrue);
    });
  });
}
