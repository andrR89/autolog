// Widget de logo reutilizável do AutoLog.
//
// Exibe o wordmark "AutoLog" em Bricolage Grotesque com um glifo de bomba
// de gasolina ao lado. Pode ser renderizado em modo claro (sobre fundo escuro)
// ou escuro (sobre fundo claro).

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';

/// Tema de cores do logo.
enum AppLogoTheme {
  /// Wordmark em cor clara — para uso sobre fundos escuros (ex: header brand).
  light,

  /// Wordmark em cor escura — para uso sobre fundos claros (ex: splash).
  dark,
}

/// Logo wordmark do AutoLog com glifo de combustível.
///
/// Uso:
/// ```dart
/// AppLogo(size: 32, logoTheme: AppLogoTheme.light) // sobre fundo brand
/// AppLogo(size: 28, logoTheme: AppLogoTheme.dark)  // sobre fundo claro
/// ```
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 32,
    this.logoTheme = AppLogoTheme.dark,
    this.showGlyph = true,
  });

  /// Tamanho base do texto (o ícone escala proporcionalmente).
  final double size;

  /// Esquema de cores do logo.
  final AppLogoTheme logoTheme;

  /// Se `true`, exibe o glifo de combustível à esquerda do wordmark.
  final bool showGlyph;

  @override
  Widget build(BuildContext context) {
    final wordmarkColor = logoTheme == AppLogoTheme.light
        ? AppColors.brandInk
        : AppColors.brand;

    final glyphBg = logoTheme == AppLogoTheme.light
        ? AppColors.accent
        : AppColors.brand;

    final glyphFg = logoTheme == AppLogoTheme.light
        ? AppColors.accentInk
        : AppColors.brandInk;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showGlyph) ...[
          _GlyphBadge(
            size: size * 1.1,
            background: glyphBg,
            foreground: glyphFg,
          ),
          SizedBox(width: size * 0.35),
        ],
        Text(
          'AutoLog',
          style: AppTypography.display(
            size,
            weight: FontWeight.w700,
            color: wordmarkColor,
          ),
        ),
      ],
    );
  }
}

/// Glifo circular com ícone de bomba de gasolina — marca visual do app.
class _GlyphBadge extends StatelessWidget {
  const _GlyphBadge({
    required this.size,
    required this.background,
    required this.foreground,
  });

  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.58;
    final badgeSize = size * 1.05;

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(badgeSize * 0.3),
      ),
      child: Center(
        child: Icon(
          Icons.local_gas_station_rounded,
          color: foreground,
          size: iconSize,
        ),
      ),
    );
  }
}
