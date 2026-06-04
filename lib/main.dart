import 'package:autolog/app.dart';
import 'package:autolog/core/config.dart';
import 'package:autolog/core/design/tokens.dart';
import 'package:autolog/features/onboarding/onboarding_repository.dart';
import 'package:autolog/features/reminders/local_notification_scheduler.dart';
import 'package:autolog/features/reminders/reminder_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bloqueia orientação em portrait — app de gestão veicular não tem uso
  // legítimo em landscape no mobile.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar e navigation bar iniciais (sobrescritos por tela onde necessário).
  // Default: ícones escuros sobre fundo claro (superfície off-white do app).
  // No Android a navigation bar acompanha o fundo do Scaffold (surface).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Android
      statusBarBrightness: Brightness.light, // iOS (dark icons)
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // intl: inicializa dados de locale pt_BR (DateFormat usa em
  // fuel_history_helpers, expenses_list_screen, etc.).
  await initializeDateFormatting('pt_BR');

  final config = SupabaseConfig.fromEnvironment();
  await Supabase.initialize(url: config.url, anonKey: config.anonKey);

  // Pré-carrega SharedPreferences ANTES do runApp para eliminar a race
  // condition no redirect do GoRouter: onboardingNeededProvider é síncrono
  // e precisa da instância já disponível na primeira avaliação do redirect
  // (cold boot). Sem isso, FutureProvider.valueOrNull retornava null antes
  // do future resolver e o router caía no auth gate → /login.
  final prefs = await SharedPreferences.getInstance();

  // Inicializa o scheduler antes do runApp: configura canais, timezone e
  // solicita permissão de notificação no iOS na primeira execução.
  final scheduler = LocalNotificationScheduler();
  await scheduler.init();

  runApp(
    ProviderScope(
      overrides: [
        notificationSchedulerProvider.overrideWithValue(scheduler),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AutoLogApp(),
    ),
  );
}
