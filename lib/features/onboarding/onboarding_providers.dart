import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/onboarding/onboarding_gate.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream de "está logado?" para invalidar o provider quando a sessão muda.
final _onboardingAuthProvider = StreamProvider<bool>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Emite `true` se o onboarding deve ser exibido ao usuário atual.
///
/// Derivação: logado E onboardingSeen == false.
/// Retorna false enquanto a sessão ainda não foi estabelecida (evita flash).
final onboardingNeededProvider = FutureProvider<bool>((ref) async {
  final isLoggedIn =
      ref.watch(_onboardingAuthProvider).valueOrNull ?? false;

  if (!isLoggedIn) return false;

  String userId;
  try {
    userId = ref.read(currentUserIdProvider);
  } catch (_) {
    return false;
  }

  final repo = ref.read(userSettingsRepositoryProvider);
  final seen = await repo.getOnboardingSeen(userId);
  return shouldShowOnboarding(seen: seen, isLoggedIn: isLoggedIn);
});
