import 'package:autolog/core/design/app_theme.dart';
import 'package:autolog/core/router.dart';
import 'package:autolog/features/auth/auth_redirect.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/settings/theme_mode_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
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
        return authRedirect(isLoggedIn: isLoggedIn, location: location);
      },
      routes: appRoutes,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
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
