// Tipografia do AutoLog.
//
// Pareamento intencional:
// - **Bricolage Grotesque** (display) — humanista grotesque variável, com
//   personalidade nos números (1 com serifa-base, 7 com travessão). Carrega
//   bem peso 600/700 sem virar "bold genérico".
// - **Manrope** (corpo) — sans-serif geométrico humanista, com tabular
//   figures naturais (ótimo para R$, km, l), boa renderização de ãõçé
//   (essencial para PT-BR), e um "g" descendente que dá calor.
//
// Tudo via `google_fonts` — cached após primeiro start.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

abstract final class AppTypography {
  /// Família display (headlines, números grandes, hero).
  ///
  /// Cor `null` (default) → herda do `DefaultTextStyle` do Theme, que segue
  /// `colorScheme.onSurface` (dinâmico light/dark). Antes era `AppColors.ink`
  /// hardcoded — quebrava o dark mode (preto em preto).
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    double? height,
    double letterSpacing = -0.02 * 16,
    Color? color,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: size * -0.015,
      color: color,
    );
  }

  /// Família corpo (UI, body, labels). Cor `null` herda do Theme — ver `display`.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// `TextTheme` Material 3 completo, montado a partir do pareamento.
  ///
  /// Estratégia: display* e headline* usam Bricolage. title*/body*/label* usam
  /// Manrope. Isso mantém a hierarquia visual e dá protagonismo ao display.
  static TextTheme buildTextTheme() {
    return TextTheme(
      // --- Display: hero numbers, splash, paywall ---
      displayLarge: display(57, weight: FontWeight.w700, height: 1.05),
      displayMedium: display(45, weight: FontWeight.w700, height: 1.08),
      displaySmall: display(36, weight: FontWeight.w600, height: 1.1),

      // --- Headline: títulos de seção, cards de destaque ---
      headlineLarge: display(32, weight: FontWeight.w600, height: 1.15),
      headlineMedium: display(28, weight: FontWeight.w600, height: 1.2),
      headlineSmall: display(24, weight: FontWeight.w600, height: 1.25),

      // --- Title: AppBar, títulos de card, dialog ---
      titleLarge: body(
        20,
        weight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      titleMedium: body(
        16,
        weight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.1,
      ),
      titleSmall: body(
        14,
        weight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0,
      ),

      // --- Body: parágrafos, descrições, valores em cards ---
      bodyLarge: body(16, weight: FontWeight.w400, height: 1.5),
      bodyMedium: body(14, weight: FontWeight.w400, height: 1.5),
      bodySmall: body(
        12,
        weight: FontWeight.w400,
        height: 1.45,
        color: AppColors.inkMuted,
      ),

      // --- Label: chips, botões, badges, overline ---
      labelLarge: body(
        14,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
      ),
      labelMedium: body(
        12,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.4,
      ),
      labelSmall: body(
        11,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.6,
        color: AppColors.inkMuted,
      ),
    );
  }

  /// Estilo dedicado a NÚMEROS de destaque (km/l, R$ grande).
  ///
  /// Usa Bricolage com tracking levemente negativo. Use direto em widgets
  /// que mostram métricas-chave (consumo, total gasto, odômetro hero).
  static TextStyle metric(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: size * -0.025,
      height: 1.0,
      color: color ?? AppColors.ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Variante mono-numérica para tabelas / listas com números alinhados.
  static TextStyle tabular(TextStyle base) {
    return base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
