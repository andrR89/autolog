// Design tokens do AutoLog.
//
// Esta é a fonte de verdade visual. Nenhum widget deve hardcodar cor, raio,
// espaçamento ou peso de fonte — sempre consumir destes tokens (ou do
// ThemeData construído a partir deles em `app_theme.dart`).
//
// Filosofia em `docs/design/design-system.md`.

import 'package:flutter/material.dart';

// ============================================================================
// Cores
// ============================================================================

/// Paleta de marca AutoLog.
///
/// Brand = verde-meia-noite (`brand`), evoca bomba de gasolina + confiança
/// com dinheiro, sem cair no azul corporativo. Acento = lima cítrica
/// (`accent`), reservada para CTAs de ação rápida (FAB, "Escanear cupom").
abstract final class AppColors {
  // --- Marca ---
  static const brand = Color(0xFF0E1F1A); // verde-meia-noite, "tinta-bomba"
  static const brandSoft = Color(0xFF1B3A30); // hover / pressed sobre brand
  static const brandInk = Color(0xFFEAF2EE); // texto sobre brand

  // --- Acento (uso parcimonioso: FAB, scan, badges "novo") ---
  static const accent = Color(0xFFC4F25C); // lima cítrica, "vai"
  static const accentInk = Color(0xFF0E1F1A); // texto sobre accent

  // --- Superfícies (off-white quente, sensibilidade BR; não branco gelado) ---
  static const surface = Color(0xFFFAF7F2); // fundo de tela
  static const surfaceRaised = Color(0xFFFFFFFF); // cards, sheets
  static const surfaceSunken = Color(0xFFF1ECE3); // inputs, chips
  static const surfaceInverse = Color(0xFF14241F);

  // --- Tinta (texto / ícones) ---
  static const ink = Color(0xFF14201C); // título / corpo principal
  static const inkMuted = Color(0xFF55615C); // metadata, subtítulos
  static const inkSoft = Color(0xFF8A938E); // placeholder, disabled
  static const hairline = Color(0xFFE3DED3); // bordas 1px, dividers

  // --- Semânticas (tonalidade calibrada para o off-white quente) ---
  static const success = Color(0xFF1F7A4D); // economia / consumo bom
  static const successSoft = Color(0xFFE6F2EB);
  static const warning = Color(0xFFB8740B); // atenção, lembrete vencendo
  static const warningSoft = Color(0xFFFBEFD8);
  static const danger = Color(0xFFB23A2F); // erro, exclusão
  static const dangerSoft = Color(0xFFF6E1DD);
  static const info = Color(0xFF2D5DA8); // info passiva (raro)
  static const infoSoft = Color(0xFFE1EAF7);

  // --- Combustível (usado em chips / ícones do tipo) ---
  static const fuelGasoline = Color(0xFFB23A2F); // gasolina → vermelho-tijolo
  static const fuelEthanol = Color(0xFF1F7A4D); // etanol → verde-cana
  static const fuelDiesel = Color(0xFF8A6E2F); // diesel → âmbar-óleo
  static const fuelFlex = Color(0xFF6B4FB8); // flex → roxo
}

// ============================================================================
// Espaçamento — grid de 4 pt
// ============================================================================

/// Tokens de espaçamento (padding, margin, gap). Tudo é múltiplo de 4.
///
/// Convenção de uso:
/// - `xs` (4): gap entre ícone e texto adjacente.
/// - `sm` (8): padding interno de chip, gap entre itens de uma linha.
/// - `md` (12): padding de campos de input.
/// - `lg` (16): padding-padrão de card e de tela.
/// - `xl` (20): separação entre seções em formulário.
/// - `xxl` (24): margem entre blocos visuais distintos.
/// - `xxxl` (32): topo/rodapé de telas, padding de empty states.
/// - `huge` (48): hero, headers grandes.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

// ============================================================================
// Raios
// ============================================================================

/// Raios de cantos. Mais suaves que o default M3 (4/12/16) para um look
/// menos "Google" e mais próximo de apps fintech BR.
abstract final class AppRadius {
  static const double sm = 8; // chips, badges, inputs
  static const double md = 14; // botões, cards
  static const double lg = 20; // sheets, dialogs, hero cards
  static const double pill = 999; // FAB, pílulas de status

  static const Radius rSm = Radius.circular(sm);
  static const Radius rMd = Radius.circular(md);
  static const Radius rLg = Radius.circular(lg);

  static const BorderRadius allSm = BorderRadius.all(rSm);
  static const BorderRadius allMd = BorderRadius.all(rMd);
  static const BorderRadius allLg = BorderRadius.all(rLg);
}

// ============================================================================
// Elevação / sombras
// ============================================================================

/// Sombras suaves (estilo "papel apoiado", não Material drop-shadow agressivo).
///
/// Default = flat (sem sombra, separação por hairline). Sombras só aparecem
/// em elementos genuinamente flutuantes: FAB, dialogs, bottom sheets, menus.
abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  /// Card "destacado" raro — quase imperceptível.
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0A000000), // ~4% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// FAB, menus suspensos.
  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x14000000), // ~8% black
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Modais / bottom sheets.
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x1F000000), // ~12% black
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];
}

// ============================================================================
// Bordas (hairlines)
// ============================================================================

abstract final class AppBorders {
  static const BorderSide hairline = BorderSide(
    color: AppColors.hairline,
    width: 1,
  );

  static const Border allHairline = Border(
    top: hairline,
    right: hairline,
    bottom: hairline,
    left: hairline,
  );
}

// ============================================================================
// Motion
// ============================================================================

/// Curvas e durações de animação. Crisp, não bouncy.
abstract final class AppMotion {
  /// Micro-interação (estado de botão, ripple).
  static const Duration fast = Duration(milliseconds: 120);

  /// Padrão (fade, slide curto, expand).
  static const Duration standard = Duration(milliseconds: 180);

  /// Transição de tela.
  static const Duration page = Duration(milliseconds: 240);

  /// Curva de entrada/saída — emphasize ease-out, sem overshoot.
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeOutQuint;
}
