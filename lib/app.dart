import 'package:autolog/core/design/app_theme.dart';
import 'package:autolog/core/router.dart';
import 'package:autolog/data/repositories/user_settings_repository.dart';
import 'package:autolog/domain/repositories/user_settings_repository.dart';
import 'package:autolog/features/auth/auth_redirect.dart';
import 'package:autolog/features/auth/auth_service.dart';
import 'package:autolog/features/vehicles/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Provider global de ThemeMode — stream-based, reativo a mudanças.
//
// Retorna [ThemeMode.system] enquanto não há sessão ativa ou enquanto
// o primeiro valor ainda não chegou do stream.
// ---------------------------------------------------------------------------

final _themeModeEnumProvider = StreamProvider<ThemeModeEnum>((ref) {
  // Se não houver sessão, não há userId — default system (stream vazio).
  String userId;
  try {
    userId = ref.watch(currentUserIdProvider);
  } catch (_) {
    return const Stream.empty();
  }
  final repo = ref.watch(userSettingsRepositoryProvider);
  return repo.watchThemeMode(userId);
});

/// ThemeMode derivado da preferência persistida do usuário.
///
/// Usado em [AutoLogApp.build] para alimentar [MaterialApp.router.themeMode].
final themeModeProvider = Provider<ThemeMode>((ref) {
  final modeEnum = ref.watch(_themeModeEnumProvider).valueOrNull;
  return switch (modeEnum) {
    ThemeModeEnum.light => ThemeMode.light,
    ThemeModeEnum.dark => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

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
