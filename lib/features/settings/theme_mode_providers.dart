// Providers de ThemeMode compartilhados entre AutoLogApp e SettingsScreen.
//
// IMPORTANTE: NUNCA criar StreamProvider inline em build() — quebra cache
// do Riverpod e a UI fica sempre lendo o valor inicial (null/system).
// Estes providers globais garantem state estável entre rebuilds.

import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream da preferência atual de tema (enum). Reativo a `setThemeMode`.
final themeModeEnumProvider = StreamProvider<ThemeModeEnum>((ref) {
  String userId;
  try {
    userId = ref.watch(currentUserIdProvider);
  } catch (_) {
    return const Stream.empty();
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
