/// Preferência de modo visual (tema) do usuário.
enum ThemeModeEnum { system, light, dark }

/// Repositório de configurações locais do usuário.
///
/// Persiste preferências de UI (ThemeMode etc.) no banco local via Drift.
/// Não sincroniza com Supabase — é local-only por design.
abstract class UserSettingsRepository {
  /// Retorna o ThemeModeEnum atual do usuário.
  ///
  /// Se não houver registro, cria um com default 'system' e retorna
  /// [ThemeModeEnum.system].
  Future<ThemeModeEnum> getThemeMode(String userId);

  /// Persiste [mode] para [userId] (insertOnConflictUpdate).
  Future<void> setThemeMode(String userId, ThemeModeEnum mode);

  /// Stream reativo: emite sempre que o themeMode do usuário mudar.
  ///
  /// Emite [ThemeModeEnum.system] enquanto ainda não há registro.
  Stream<ThemeModeEnum> watchThemeMode(String userId);
}
