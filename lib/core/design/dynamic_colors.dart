import 'package:flutter/material.dart';

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
}
