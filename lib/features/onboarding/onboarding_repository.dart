import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Provider síncrono de SharedPreferences
// ---------------------------------------------------------------------------

/// Override **obrigatório** no main() com a instância já carregada.
///
/// Pré-carregar no main() elimina a race condition em cold boot: o redirect
/// do GoRouter avalia o [onboardingNeededProvider] sincronamente na primeira
/// chamada, antes de qualquer future resolver.
///
/// Sem override, lança [UnimplementedError] para forçar boot correto.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider precisa ser overridden no main() — '
    'use SharedPreferences.getInstance() antes de runApp.',
  );
});

// ---------------------------------------------------------------------------
// Contrato
// ---------------------------------------------------------------------------

/// Repositório responsável por persistir o estado de "onboarding visto".
///
/// Propositalmente desacoplado de qualquer userId: o onboarding roda
/// ANTES do login (marketing pré-login), então não há userId disponível.
abstract class OnboardingRepository {
  /// Retorna `true` se o usuário já viu o onboarding neste dispositivo.
  ///
  /// Síncrono: requer [SharedPreferences] já inicializado via
  /// [sharedPreferencesProvider] para não bloquear o redirect do router.
  bool hasSeenOnboarding();

  /// Marca o onboarding como visto neste dispositivo.
  Future<void> markSeen();
}

// ---------------------------------------------------------------------------
// Implementação SharedPreferences (produção)
// ---------------------------------------------------------------------------

class SharedPrefsOnboardingRepository implements OnboardingRepository {
  SharedPrefsOnboardingRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'onboarding_seen';

  @override
  bool hasSeenOnboarding() => _prefs.getBool(_key) ?? false;

  @override
  Future<void> markSeen() async {
    await _prefs.setBool(_key, true);
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
  bool hasSeenOnboarding() => _seen;

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
/// Depende de [sharedPreferencesProvider] que deve ser overridden no main()
/// com a instância pré-carregada antes do runApp.
///
/// Para testes, sobrescreva com [InMemoryOnboardingRepository] ou use
/// [sharedPreferencesProvider] com mock values.
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsOnboardingRepository(prefs);
});
