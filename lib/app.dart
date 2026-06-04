import 'dart:async';

import 'package:autolog/core/design/app_theme.dart';
import 'package:autolog/core/router.dart';
import 'package:autolog/data/local/database.dart';
import 'package:autolog/features/auth/auth_redirect.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/home_widget/home_widget_service.dart';
import 'package:autolog/features/onboarding/onboarding_providers.dart';
import 'package:autolog/features/settings/theme_mode_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Providers de ThemeMode foram movidos pra
// `features/settings/theme_mode_providers.dart` pra serem compartilhados
// entre AutoLogApp e SettingsScreen (evita provider inline que descartava
// state a cada rebuild — bug 27/05/2026).

// ---------------------------------------------------------------------------
// App root
// ---------------------------------------------------------------------------

class AutoLogApp extends ConsumerStatefulWidget {
  const AutoLogApp({super.key});

  @override
  ConsumerState<AutoLogApp> createState() => _AutoLogAppState();
}

class _AutoLogAppState extends ConsumerState<AutoLogApp> {
  late final GoRouter _router;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
    _scheduleWidgetRefreshOnLogin();
  }

  /// Dispara refresh do widget quando o usuário entra/sai.
  /// Fire-and-forget — nunca bloqueia nem propaga erro.
  /// Guard try/catch: em ambiente de testes, Supabase pode não estar
  /// inicializado e chamamos silenciosamente (widget é cosmético).
  void _scheduleWidgetRefreshOnLogin() {
    try {
      final supabase = Supabase.instance.client;
      _authSub = supabase.auth.onAuthStateChange.listen((event) {
        final session = event.session;
        if (session != null) {
          final db = ref.read(appDatabaseProvider);
          final widgetService = ref.read(homeWidgetServiceProvider);
          // ignore: discarded_futures
          widgetService.refresh(db: db, userId: session.user.id);
        }
      });
    } catch (_) {
      // Supabase não inicializado (ex: testes unitários). Ignora silenciosamente.
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _router.dispose();
    super.dispose();
  }

  GoRouter _buildRouter() {
    final authService = ref.read(authServiceProvider);
    final notifier = RouterNotifier(authService.authStateChanges);

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: notifier,
      redirect: (context, state) {
        final isLoggedIn = ref.read(authServiceProvider).isLoggedIn;
        final location = state.uri.toString();

        // 1. Onboarding gate — avaliado ANTES do auth gate.
        //    Onboarding é marketing pré-login: aparece quando o usuário nunca
        //    viu E não está logado. Lê do SharedPreferences (sem userId).
        //    Não redireciona se já está em /onboarding.
        if (location != '/onboarding') {
          final needed = ref.read(onboardingNeededProvider).valueOrNull;
          if (needed == true) return '/onboarding';
        }

        // 2. Auth gate — redireciona para /login se não logado fora de rota
        //    pública/auth; redireciona para /home se logado em rota de auth.
        //    /onboarding é rota pública e não é bloqueada aqui.
        final authDest = authRedirect(
          isLoggedIn: isLoggedIn,
          location: location,
        );
        if (authDest != null) return authDest;

        return null;
      },
      routes: appRoutes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AutoLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
