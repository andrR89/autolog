// Providers de NotificationPreferences compartilhados entre SettingsScreen e
// qualquer widget que precise exibir/alterar preferências de notificação.
//
// IMPORTANTE: NUNCA criar StreamProvider inline em build() — quebra cache do
// Riverpod e a UI fica sempre lendo o valor inicial.
// Estes providers globais garantem state estável entre rebuilds.

import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream de "está logado?" — reutilizado para evitar dependência circular
/// com theme_mode_providers (que é privado lá).
final _notifAuthStateProvider = StreamProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Stream das preferências de notificação do usuário atual. Reativo a
/// `setNotifPref` e a mudanças de auth — quando o user loga após o startup,
/// o provider re-executa e troca de Stream.value(defaults) pro stream real.
final notifPrefsProvider = StreamProvider<NotificationPreferences>((ref) {
  final isLoggedIn =
      ref.watch(_notifAuthStateProvider).valueOrNull ?? false;
  if (!isLoggedIn) return Stream.value(const NotificationPreferences());

  String userId;
  try {
    userId = ref.watch(currentUserIdProvider);
  } catch (_) {
    return Stream.value(const NotificationPreferences());
  }

  final repo = ref.watch(userSettingsRepositoryProvider);
  return repo.watchNotifPrefs(userId);
});
