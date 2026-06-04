import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Contrato
// ---------------------------------------------------------------------------

/// Repositório responsável por persistir o estado de "onboarding visto".
///
/// Propositalmente desacoplado de qualquer userId: o onboarding roda
/// ANTES do login (marketing pré-login), então não há userId disponível.
abstract class OnboardingRepository {
  /// Retorna `true` se o usuário já viu o onboarding neste dispositivo.
  Future<bool> hasSeenOnboarding();

  /// Marca o onboarding como visto neste dispositivo.
  Future<void> markSeen();
}

// ---------------------------------------------------------------------------
// Implementação SharedPreferences (produção)
// ---------------------------------------------------------------------------

class SharedPrefsOnboardingRepository implements OnboardingRepository {
  static const _key = 'onboarding_seen';

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}

// ---------------------------------------------------------------------------
// Implementação em memória (testes)
// ---------------------------------------------------------------------------

/// Implementação em memória para uso exclusivo em testes.
///
/// Estado começa como `false` (não visto). Não persiste entre instâncias.
class InMemoryOnboardingRepository implements OnboardingRepository {
  bool _seen = false;

  @override
  Future<bool> hasSeenOnboarding() async => _seen;

  @override
  Future<void> markSeen() async {
    _seen = true;
  }
}

// ---------------------------------------------------------------------------
// Provider Riverpod
// ---------------------------------------------------------------------------

/// Provider global do repositório de onboarding (SharedPreferences).
///
/// Para testes, sobrescreva com [InMemoryOnboardingRepository].
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return SharedPrefsOnboardingRepository();
});
