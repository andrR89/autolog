// `ThemeData` do AutoLog, montado a partir dos tokens em `tokens.dart` e
// `typography.dart`.
//
// Regra: nenhum widget configura cor/raio/peso por conta própria. Tudo o que
// faz sentido propagar (botões, inputs, cards, app bar, snackbar, dialog,
// FAB, chips, dividers, switches) está pré-configurado aqui.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';
import 'typography.dart';

// ============================================================================
// Paleta dark — invertida, mantém brand verde e accent lima
// ============================================================================

abstract final class _DarkColors {
  // Superfícies
  static const surface = Color(0xFF101816); // fundo de tela — verde-escuro profundo
  static const surfaceRaised = Color(0xFF18231F); // cards, sheets — levemente mais claro
  static const surfaceSunken = Color(0xFF0C1310); // inputs, chips — mais escuro que surface
  static const surfaceInverse = Color(0xFFEAF2EE); // snackbar inverse

  // Tinta (texto/ícones em fundo escuro)
  static const ink = Color(0xFFF0EDE7); // texto principal — off-white quente
  static const inkMuted = Color(0xFFA8B0AC); // metadados, subtítulos
  static const inkSoft = Color(0xFF6B7571); // placeholder, disabled

  // Hairline visível em fundo escuro
  static const hairline = Color(0xFF2A3832);
}

/// Namespace estático para acessar temas light/dark do app.
abstract final class AppTheme {
  static ThemeData get light => buildLightTheme();
  static ThemeData get dark => buildDarkTheme();
}

/// Tema claro padrão do app.
ThemeData buildLightTheme() {
  final textTheme = AppTypography.buildTextTheme();

  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    // primary = marca; usado em CTAs principais (FilledButton, AppBar accents)
    primary: AppColors.brand,
    onPrimary: AppColors.brandInk,
    primaryContainer: AppColors.brandSoft,
    onPrimaryContainer: AppColors.brandInk,
    // secondary = acento lima; reservar para "go" moments (FAB / scan)
    secondary: AppColors.accent,
    onSecondary: AppColors.accentInk,
    secondaryContainer: AppColors.accent,
    onSecondaryContainer: AppColors.accentInk,
    // tertiary = warning amber, ocasional uso material
    tertiary: AppColors.warning,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.warningSoft,
    onTertiaryContainer: AppColors.warning,
    // surfaces — off-white quente
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    surfaceContainerLowest: AppColors.surfaceRaised,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surfaceSunken,
    surfaceContainerHigh: AppColors.surfaceSunken,
    surfaceContainerHighest: AppColors.surfaceSunken,
    onSurfaceVariant: AppColors.inkMuted,
    surfaceTint: AppColors.brand,
    inverseSurface: AppColors.surfaceInverse,
    onInverseSurface: AppColors.brandInk,
    inversePrimary: AppColors.accent,
    // borders
    outline: AppColors.hairline,
    outlineVariant: AppColors.hairline,
    // semantic
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.danger,
    // scrim
    shadow: Color(0x14000000),
    scrim: Color(0x66000000),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    canvasColor: AppColors.surface,
    textTheme: textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  return base.copyWith(
    // ------------------------------------------------------------------
    // App bar — flat, transparente sobre o off-white, título grande
    // ------------------------------------------------------------------
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: AppSpacing.lg,
      toolbarHeight: 60,
      iconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      actionsIconTheme: const IconThemeData(color: AppColors.ink, size: 22),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // ------------------------------------------------------------------
    // Cards — flat com hairline em vez de drop shadow
    // ------------------------------------------------------------------
    cardTheme: const CardThemeData(
      color: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allMd,
        side: AppBorders.hairline,
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // ------------------------------------------------------------------
    // Botões
    // ------------------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.brandInk,
        disabledBackgroundColor: AppColors.surfaceSunken,
        disabledForegroundColor: AppColors.inkSoft,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: AppBorders.hairline,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(44, 44),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      ),
    ),

    // ------------------------------------------------------------------
    // FAB — pílula lima cítrica, único elemento com sombra "flutuante"
    // ------------------------------------------------------------------
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.accentInk,
      splashColor: AppColors.brandSoft.withValues(alpha: 0.12),
      hoverColor: AppColors.brandSoft.withValues(alpha: 0.06),
      focusColor: AppColors.brandSoft.withValues(alpha: 0.12),
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 6,
      highlightElevation: 2,
      shape: const StadiumBorder(),
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        color: AppColors.accentInk,
        fontWeight: FontWeight.w700,
      ),
    ),

    // ------------------------------------------------------------------
    // Inputs — fundo "sunken" quente, sem borda externa, foco com brand
    // ------------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSunken,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
      labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
      floatingLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.brand,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: AppColors.inkMuted,
      suffixIconColor: AppColors.inkMuted,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppColors.brand, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppColors.danger, width: 2),
      ),
      errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.danger),
    ),

    // ------------------------------------------------------------------
    // Chips, list tiles, dividers
    // ------------------------------------------------------------------
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceSunken,
      selectedColor: AppColors.brand,
      secondarySelectedColor: AppColors.accent,
      checkmarkColor: AppColors.brandInk,
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.brandInk,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.inkMuted,
      textColor: AppColors.ink,
      titleTextStyle: textTheme.titleMedium,
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.inkMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      minVerticalPadding: AppSpacing.md,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
    ),

    // ------------------------------------------------------------------
    // Dialogs, sheets, snackbars, menus
    // ------------------------------------------------------------------
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.surfaceRaised,
      modalElevation: 0,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: AppColors.hairline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.rLg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceInverse,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.brandInk,
      ),
      actionTextColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      elevation: 0,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.allMd,
        side: AppBorders.hairline,
      ),
      textStyle: textTheme.bodyMedium,
    ),

    // ------------------------------------------------------------------
    // Switches / checkboxes / radios — brand color quando ativo
    // ------------------------------------------------------------------
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.brandInk;
        return AppColors.surfaceRaised;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.brand;
        return AppColors.surfaceSunken;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.brand;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.brandInk),
      side: AppBorders.hairline,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.brand;
        return AppColors.inkSoft;
      }),
    ),

    // ------------------------------------------------------------------
    // Progress / loaders
    // ------------------------------------------------------------------
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.brand,
      linearTrackColor: AppColors.surfaceSunken,
      circularTrackColor: AppColors.surfaceSunken,
    ),

    // ------------------------------------------------------------------
    // Tabs, tooltips
    // ------------------------------------------------------------------
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.brand,
      unselectedLabelColor: AppColors.inkMuted,
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
      indicatorColor: AppColors.brand,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: AppColors.hairline,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: const BoxDecoration(
        color: AppColors.surfaceInverse,
        borderRadius: AppRadius.allSm,
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: AppColors.brandInk),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      waitDuration: const Duration(milliseconds: 600),
    ),
  );
}

/// Tema escuro do AutoLog.
///
/// Mantém a identidade de marca (verde-meia-noite + accent lima).
/// Superfícies são invertidas; texto claro sobre fundo escuro.
/// Telas que hardcodam [AppColors] vão continuar "claras" — OK para o MVP.
ThemeData buildDarkTheme() {
  final textTheme = AppTypography.buildTextTheme();

  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    // primary = marca; preservado em ambos os temas
    primary: AppColors.brand,
    onPrimary: AppColors.brandInk,
    primaryContainer: AppColors.brandSoft,
    onPrimaryContainer: AppColors.brandInk,
    // secondary = acento lima
    secondary: AppColors.accent,
    onSecondary: AppColors.accentInk,
    secondaryContainer: AppColors.accent,
    onSecondaryContainer: AppColors.accentInk,
    // tertiary = warning
    tertiary: AppColors.warning,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.warningSoft,
    onTertiaryContainer: AppColors.warning,
    // surfaces escuras
    surface: _DarkColors.surface,
    onSurface: _DarkColors.ink,
    surfaceContainerLowest: _DarkColors.surfaceRaised,
    surfaceContainerLow: _DarkColors.surface,
    surfaceContainer: _DarkColors.surfaceSunken,
    surfaceContainerHigh: _DarkColors.surfaceSunken,
    surfaceContainerHighest: _DarkColors.surfaceSunken,
    onSurfaceVariant: _DarkColors.inkMuted,
    surfaceTint: AppColors.brand,
    inverseSurface: _DarkColors.surfaceInverse,
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.accent,
    // borders
    outline: _DarkColors.hairline,
    outlineVariant: _DarkColors.hairline,
    // semantic
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: AppColors.dangerSoft,
    onErrorContainer: AppColors.danger,
    // scrim
    shadow: Color(0x33000000),
    scrim: Color(0x99000000),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _DarkColors.surface,
    canvasColor: _DarkColors.surface,
    textTheme: textTheme.apply(
      bodyColor: _DarkColors.ink,
      displayColor: _DarkColors.ink,
    ),
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  return base.copyWith(
    // ------------------------------------------------------------------
    // App bar — fundo escuro profundo, texto/ícones claros
    // ------------------------------------------------------------------
    appBarTheme: AppBarTheme(
      backgroundColor: _DarkColors.surface,
      foregroundColor: _DarkColors.ink,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: AppSpacing.lg,
      toolbarHeight: 60,
      iconTheme: const IconThemeData(color: _DarkColors.ink, size: 22),
      actionsIconTheme: const IconThemeData(color: _DarkColors.ink, size: 22),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: _DarkColors.ink,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // ------------------------------------------------------------------
    // Cards — surface raised escuro, hairline dark
    // ------------------------------------------------------------------
    cardTheme: const CardThemeData(
      color: _DarkColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allMd,
        side: BorderSide(color: _DarkColors.hairline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // ------------------------------------------------------------------
    // Botões
    // ------------------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.brandInk,
        disabledBackgroundColor: _DarkColors.surfaceSunken,
        disabledForegroundColor: _DarkColors.inkSoft,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _DarkColors.ink,
        side: const BorderSide(color: _DarkColors.hairline, width: 1),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _DarkColors.ink,
        minimumSize: const Size(44, 44),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      ),
    ),

    // ------------------------------------------------------------------
    // FAB — accent lima, mantido idêntico
    // ------------------------------------------------------------------
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.accentInk,
      splashColor: AppColors.brandSoft.withValues(alpha: 0.12),
      hoverColor: AppColors.brandSoft.withValues(alpha: 0.06),
      focusColor: AppColors.brandSoft.withValues(alpha: 0.12),
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 6,
      highlightElevation: 2,
      shape: const StadiumBorder(),
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        color: AppColors.accentInk,
        fontWeight: FontWeight.w700,
      ),
    ),

    // ------------------------------------------------------------------
    // Inputs — fundo sunken escuro
    // ------------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _DarkColors.surfaceSunken,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: _DarkColors.inkSoft),
      labelStyle: textTheme.bodyMedium?.copyWith(color: _DarkColors.inkMuted),
      floatingLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.accent,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: _DarkColors.inkMuted,
      suffixIconColor: _DarkColors.inkMuted,
      border: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide.none,
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppColors.danger, width: 2),
      ),
      errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.danger),
    ),

    // ------------------------------------------------------------------
    // Chips, list tiles, dividers
    // ------------------------------------------------------------------
    chipTheme: ChipThemeData(
      backgroundColor: _DarkColors.surfaceSunken,
      selectedColor: AppColors.brand,
      secondarySelectedColor: AppColors.accent,
      checkmarkColor: AppColors.brandInk,
      labelStyle: textTheme.labelMedium?.copyWith(color: _DarkColors.ink),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.brandInk,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: _DarkColors.hairline,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: _DarkColors.inkMuted,
      textColor: _DarkColors.ink,
      titleTextStyle: textTheme.titleMedium?.copyWith(color: _DarkColors.ink),
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: _DarkColors.inkMuted,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      minVerticalPadding: AppSpacing.md,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
    ),

    // ------------------------------------------------------------------
    // Dialogs, sheets, snackbars, menus
    // ------------------------------------------------------------------
    dialogTheme: DialogThemeData(
      backgroundColor: _DarkColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: _DarkColors.ink),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: _DarkColors.ink),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _DarkColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: _DarkColors.surfaceRaised,
      modalElevation: 0,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: _DarkColors.hairline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: AppRadius.rLg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _DarkColors.surfaceInverse,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.ink,
      ),
      actionTextColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      elevation: 0,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _DarkColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.allMd,
        side: BorderSide(color: _DarkColors.hairline, width: 1),
      ),
      textStyle: textTheme.bodyMedium?.copyWith(color: _DarkColors.ink),
    ),

    // ------------------------------------------------------------------
    // Switches / checkboxes / radios — accent quando ativo no dark
    // ------------------------------------------------------------------
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accentInk;
        return _DarkColors.surfaceRaised;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return _DarkColors.surfaceSunken;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.accentInk),
      side: const BorderSide(color: _DarkColors.hairline, width: 1),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return _DarkColors.inkSoft;
      }),
    ),

    // ------------------------------------------------------------------
    // Progress / loaders
    // ------------------------------------------------------------------
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: _DarkColors.surfaceSunken,
      circularTrackColor: _DarkColors.surfaceSunken,
    ),

    // ------------------------------------------------------------------
    // Tabs, tooltips
    // ------------------------------------------------------------------
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.accent,
      unselectedLabelColor: _DarkColors.inkMuted,
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
      indicatorColor: AppColors.accent,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: _DarkColors.hairline,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _DarkColors.surfaceRaised,
        borderRadius: AppRadius.allSm,
        border: Border.all(color: _DarkColors.hairline),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: _DarkColors.ink),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      waitDuration: const Duration(milliseconds: 600),
    ),
  );
}
