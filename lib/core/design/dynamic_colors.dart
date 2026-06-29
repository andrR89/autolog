import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Cores reativas ao Theme — usar em vez de AppColors hardcoded em
/// widgets que devem responder a dark mode.
extension DynamicColors on BuildContext {
  ColorScheme get _cs => Theme.of(this).colorScheme;
  Brightness get _brightness => Theme.of(this).brightness;
  bool get isDark => _brightness == Brightness.dark;

  Color get surface => Theme.of(this).scaffoldBackgroundColor;
  Color get surfaceRaised => _cs.surfaceContainerHighest;
  Color get surfaceSunken => _cs.surfaceContainerLow;
  Color get ink => _cs.onSurface;
  Color get inkMuted => _cs.onSurfaceVariant;
  Color get inkSoft => _cs.onSurfaceVariant.withValues(alpha: 0.6);
  Color get hairline => Theme.of(this).dividerColor;

  /// Estilo de status bar responsivo ao tema: ícones claros no dark mode,
  /// escuros no light mode. Usar em telas com fundo surface (não brand).
  SystemUiOverlayStyle get systemUiStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
  );
}
