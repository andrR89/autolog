import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/onboarding/onboarding_gate.dart';
import 'package:autolog/features/onboarding/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream de "está logado?" para invalidar o provider quando a sessão muda.
final _onboardingAuthProvider = StreamProvider<bool>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Emite `true` se o onboarding deve ser exibido.
///
/// Lógica nova (fix caso B — onboarding é marketing pré-login):
/// - Lê `seen` do [OnboardingRepository] (SharedPreferences, pré-login).
/// - Lê `isLoggedIn` do stream de auth.
/// - Delega decisão ao [shouldShowOnboarding] puro.
///
/// Retorna `false` enquanto o estado ainda não foi carregado para evitar flash.
final onboardingNeededProvider = FutureProvider<bool>((ref) async {
  // isLoggedIn pode ser false mesmo antes da sessão estar estabelecida — ok,
  // pois o gate agora exibe para não-logados que nunca viram.
  final isLoggedIn = ref.watch(_onboardingAuthProvider).valueOrNull ?? false;

  final repo = ref.read(onboardingRepositoryProvider);
  final seen = await repo.hasSeenOnboarding();

  return shouldShowOnboarding(seen: seen, isLoggedIn: isLoggedIn);
});
