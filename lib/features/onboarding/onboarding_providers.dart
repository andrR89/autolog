import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/onboarding/onboarding_gate.dart';
import 'package:autolog/features/onboarding/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado síncrono de "está logado?" derivado do [authServiceProvider].
///
/// Separado em provider próprio para ser overrideable em testes sem
/// precisar mockar authServiceProvider inteiro.
final authIsLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isLoggedIn;
});

/// Emite `true` se o onboarding deve ser exibido.
///
/// **Síncrono** (`Provider<bool>`, não `FutureProvider`): depende de
/// [sharedPreferencesProvider] que é pré-carregado no main() antes do
/// runApp. Isso elimina a race condition em cold boot onde o redirect do
/// GoRouter avaliava FutureProvider.valueOrNull → null antes do future
/// resolver → caía no auth gate → /login.
///
/// Lógica:
/// - Já viu → false.
/// - Logado → false (já é usuário; passou da fase de conversão).
/// - Nunca viu E não logado → true.
final onboardingNeededProvider = Provider<bool>((ref) {
  final repo = ref.watch(onboardingRepositoryProvider);
  final isLoggedIn = ref.watch(authIsLoggedInProvider);
  return shouldShowOnboarding(
    seen: repo.hasSeenOnboarding(),
    isLoggedIn: isLoggedIn,
  );
});
