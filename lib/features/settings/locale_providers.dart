// Locale provider — persistido em SharedPreferences sem userId.
//
// Por que SharedPreferences e não user_settings (Drift): o user escolhe
// idioma ANTES de logar (ex.: na tela de login). Igual o tema é tratado
// via Drift por usuário, mas pra MVP do i18n queremos algo que funciona
// pré-login. Quando estabilizar, pode migrar pra user_settings sincronizado.

import 'package:autolog/features/onboarding/onboarding_repository.dart'
    show sharedPreferencesProvider;
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kLocaleKey = 'locale_code';

/// Locales suportados — ordem afeta a UI do seletor.
const supportedLocales = <Locale>[
  Locale('pt'),
  Locale('en'),
  Locale('es'),
];

/// Notifier do locale persistido. `null` = "padrão do sistema".
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final code = prefs.getString(_kLocaleKey);
    if (code == null || code.isEmpty) return null;
    return Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_kLocaleKey);
    } else {
      await prefs.setString(_kLocaleKey, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Helper pra UI mostrar o nome do idioma.
String localeDisplayName(Locale locale) {
  switch (locale.languageCode) {
    case 'pt':
      return 'Português';
    case 'en':
      return 'English';
    case 'es':
      return 'Español';
    default:
      return locale.languageCode.toUpperCase();
  }
}
