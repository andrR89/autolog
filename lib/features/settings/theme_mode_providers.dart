// Providers de ThemeMode compartilhados entre AutoLogApp e SettingsScreen.
//
// IMPORTANTE: NUNCA criar StreamProvider inline em build() — quebra cache
// do Riverpod e a UI fica sempre lendo o valor inicial (null/system).
// Estes providers globais garantem state estável entre rebuilds.

import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream de "está logado?" pra usar como gatilho de re-execução de
/// outros providers que dependem de sessão.
final _authStateChangesProvider = StreamProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Stream da preferência atual de tema (enum). Reativo a `setThemeMode` E
/// a mudanças de auth — quando o user loga após o startup, o provider
/// re-executa e troca de `Stream.empty()` pro stream real do Drift.
///
/// Bug 27/05/2026: sem o watch do auth state, este provider ficava com
/// cache de `Stream.empty()` pra sempre se o app abrisse antes da sessão
/// estabelecer — radio em Settings funcionava, mas o tema do MaterialApp
/// nunca atualizava (ficava em system).
final themeModeEnumProvider = StreamProvider<ThemeModeEnum>((ref) {
  final isLoggedIn =
      ref.watch(_authStateChangesProvider).valueOrNull ?? false;
  if (!isLoggedIn) return Stream.value(ThemeModeEnum.system);

  String userId;
  try {
    userId = ref.watch(currentUserIdProvider);
  } catch (_) {
    return Stream.value(ThemeModeEnum.system);
  }
  final repo = ref.watch(userSettingsRepositoryProvider);
  return repo.watchThemeMode(userId);
});

/// ThemeMode derivado da preferência (pra alimentar MaterialApp.themeMode).
final themeModeProvider = Provider<ThemeMode>((ref) {
  final modeEnum = ref.watch(themeModeEnumProvider).valueOrNull;
  return switch (modeEnum) {
    ThemeModeEnum.light => ThemeMode.light,
    ThemeModeEnum.dark => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});
