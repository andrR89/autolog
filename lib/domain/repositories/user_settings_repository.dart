/// Preferência de modo visual (tema) do usuário.
enum ThemeModeEnum { system, light, dark }

/// Preferências de notificações proativas por categoria.
///
/// Defaults: todas ligadas (opt-out). Cada campo mapeia a uma categoria do
/// [notification_evaluator].
class NotificationPreferences {
  const NotificationPreferences({
    this.consumptionDrop = true,
    this.cnh = true,
    this.fiscal = true,
    this.recapReady = true,
  });

  final bool consumptionDrop;
  final bool cnh;
  final bool fiscal;
  final bool recapReady;

  /// Retorna `true` se a categoria [category] está habilitada.
  ///
  /// Categorias desconhecidas retornam `true` (permissivo por padrão).
  bool enabled(String category) => switch (category) {
        'consumption_drop' => consumptionDrop,
        'cnh' => cnh,
        'fiscal' => fiscal,
        'recap_ready' => recapReady,
        _ => true,
      };
}

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

  /// Retorna as preferências de notificação do usuário.
  ///
  /// Se não houver registro, cria com defaults (todas ligadas) e retorna.
  Future<NotificationPreferences> getNotifPrefs(String userId);

  /// Persiste a preferência de uma categoria específica.
  ///
  /// [category] deve ser um de: 'consumption_drop', 'cnh', 'fiscal',
  /// 'recap_ready'. Não sobrescreve os outros campos.
  Future<void> setNotifPref(String userId, String category, bool enabled);

  /// Stream reativo: emite sempre que qualquer pref de notif mudar.
  Stream<NotificationPreferences> watchNotifPrefs(String userId);

  // ---------------------------------------------------------------------------
  // Onboarding (Sprint 6.GG)
  // ---------------------------------------------------------------------------

  /// Retorna true se o usuário já concluiu o tour de onboarding.
  ///
  /// Default: false (nunca viu).
  Future<bool> getOnboardingSeen(String userId);

  /// Marca o tour como concluído para [userId].
  Future<void> setOnboardingSeen(String userId);
}
