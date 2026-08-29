import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_tokens.dart';
import 'vistar_palette.dart';

/// Builds the two Vistar Premium themes from a single [VistarPalette], so light
/// and dark stay in lockstep: change a token once, both modes follow.
class AppTheme {
  AppTheme._();

  /// Display face — page titles, KPI numbers, the brand name.
  static TextStyle _display(
    Color color, {
    required double size,
    required FontWeight weight,
    double letterSpacing = -0.4,
    double? height,
  }) {
    return GoogleFonts.bricolageGrotesque(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Body face — labels, table text, inputs.
  static TextStyle _body(
    Color color, {
    required double size,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.1,
    double? height,
  }) {
    return GoogleFonts.manrope(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextTheme _textTheme(VistarPalette p) {
    return TextTheme(
      // Bricolage Grotesque, letter-spacing -.4px
      displayLarge: _display(p.txt, size: 44, weight: FontWeight.w800, letterSpacing: -1.0),
      displayMedium: _display(p.txt, size: 36, weight: FontWeight.w800, letterSpacing: -0.8),
      displaySmall: _display(p.txt, size: 30, weight: FontWeight.w800, letterSpacing: -0.6),
      headlineLarge: _display(p.txt, size: 32, weight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: _display(p.txt, size: 24, weight: FontWeight.w800),
      headlineSmall: _display(p.txt, size: 18, weight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: _display(p.txt, size: 16, weight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: _display(p.txt, size: 15, weight: FontWeight.w700, letterSpacing: -0.2),
      titleSmall: _body(p.txt, size: 13, weight: FontWeight.w700),

      // Manrope, letter-spacing .1px
      bodyLarge: _body(p.txt, size: 14, weight: FontWeight.w500, height: 1.45),
      bodyMedium: _body(p.txt2, size: 13, weight: FontWeight.w500, height: 1.5),
      bodySmall: _body(p.txt2, size: 12, weight: FontWeight.w500, height: 1.45),

      labelLarge: _body(p.txt, size: 13, weight: FontWeight.w700),
      labelMedium: _body(p.txt2, size: 12, weight: FontWeight.w600),
      // Uppercase group labels / table heads
      labelSmall: _body(p.txt3, size: 11, weight: FontWeight.w700, letterSpacing: 0.6),
    );
  }

  static ThemeData _build(VistarPalette p) {
    final isDark = p.isDark;
    final text = _textTheme(p);

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      extensions: <ThemeExtension<dynamic>>[p],

      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: p.surface,
      dividerColor: p.line,
      primaryColor: AppColors.pink,
      shadowColor: p.shadowColor,
      splashColor: AppColors.pink.withValues(alpha: 0.08),
      highlightColor: AppColors.pink.withValues(alpha: 0.05),
      hoverColor: p.surface3.withValues(alpha: isDark ? 0.5 : 0.7),

      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: AppColors.pink,
        onPrimary: Colors.white,
        primaryContainer: p.brandTint,
        onPrimaryContainer: p.brandInk,
        secondary: AppColors.orange,
        onSecondary: Colors.white,
        secondaryContainer: p.warnTint,
        onSecondaryContainer: p.warn,
        tertiary: AppColors.violet,
        onTertiary: Colors.white,
        error: p.bad,
        onError: Colors.white,
        errorContainer: p.badTint,
        onErrorContainer: p.bad,
        surface: p.surface,
        onSurface: p.txt,
        surfaceContainerLowest: p.bg,
        surfaceContainerLow: p.bg2,
        surfaceContainer: p.surface,
        surfaceContainerHigh: p.surface2,
        surfaceContainerHighest: p.surface3,
        onSurfaceVariant: p.txt2,
        outline: p.line2,
        outlineVariant: p.line,
        inverseSurface: isDark ? p.txt : p.bg,
        onInverseSurface: isDark ? p.bg : p.txt,
        shadow: p.shadowColor,
        scrim: Colors.black.withValues(alpha: 0.55),
      ),

      textTheme: text,
      primaryTextTheme: text,

      iconTheme: IconThemeData(color: p.txt2, size: 20),
      primaryIconTheme: IconThemeData(color: p.txt, size: 20),

      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.txt,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _display(p.txt, size: 17, weight: FontWeight.w700),
        iconTheme: IconThemeData(color: p.txt2, size: 20),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.r),
          side: BorderSide(color: p.line),
        ),
      ),

      // .inp — pink focus ring in both modes
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: BorderSide(color: AppColors.pink.withValues(alpha: 0.6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: BorderSide(color: p.bad),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: BorderSide(color: p.bad, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: BorderSide(color: p.line.withValues(alpha: 0.5)),
        ),
        labelStyle: _body(p.txt2, size: 13),
        floatingLabelStyle: _body(p.brandInk, size: 12, weight: FontWeight.w700),
        hintStyle: _body(p.txt3, size: 13),
        helperStyle: _body(p.txt3, size: 11),
        errorStyle: _body(p.bad, size: 11, weight: FontWeight.w600),
        prefixIconColor: p.txt3,
        suffixIconColor: p.txt3,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: _body(p.txt, size: 13),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface2),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.rSm),
              side: BorderSide(color: p.line),
            ),
          ),
        ),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface2),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.rSm),
              side: BorderSide(color: p.line),
            ),
          ),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: p.surface2,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        textStyle: _body(p.txt, size: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          side: BorderSide(color: p.line),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.rLg),
          side: BorderSide(color: p.line),
        ),
        titleTextStyle: _display(p.txt, size: 18, weight: FontWeight.w700),
        contentTextStyle: _body(p.txt2, size: 13, height: 1.5),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.rLg)),
          side: BorderSide(color: p.line),
        ),
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? p.surface3 : const Color(0xFF231C46),
        contentTextStyle: _body(Colors.white, size: 13, weight: FontWeight.w600),
        actionTextColor: AppColors.amber,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rSm)),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? p.surface3 : const Color(0xFF231C46),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: p.line2),
        ),
        textStyle: _body(Colors.white, size: 11.5, weight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surface2,
        selectedColor: AppColors.pink,
        disabledColor: p.surface,
        surfaceTintColor: Colors.transparent,
        labelStyle: _body(p.txt2, size: 12, weight: FontWeight.w600),
        secondaryLabelStyle: _body(Colors.white, size: 12, weight: FontWeight.w700),
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: p.txt,
        unselectedLabelColor: p.txt3,
        indicatorColor: AppColors.pink,
        dividerColor: p.line,
        labelStyle: _body(p.txt, size: 13, weight: FontWeight.w700),
        unselectedLabelStyle: _body(p.txt3, size: 13, weight: FontWeight.w500),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: p.txt2,
        textColor: p.txt,
        titleTextStyle: _body(p.txt, size: 13.5, weight: FontWeight.w600),
        subtitleTextStyle: _body(p.txt3, size: 12),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.pink : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: p.line2, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.pink : p.txt3,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : p.txt3,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.pink : p.surface3,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.line2),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.pink,
        linearTrackColor: p.surface3,
        circularTrackColor: p.surface3,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.pink,
        inactiveTrackColor: p.surface3,
        thumbColor: AppColors.pink,
        overlayColor: AppColors.pink.withValues(alpha: 0.12),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(p.surface2),
        headingTextStyle: _body(p.txt3, size: 11, weight: FontWeight.w700, letterSpacing: 0.6),
        dataTextStyle: _body(p.txt2, size: 13),
        dividerThickness: 1,
      ),

      // Translucent pink selection, per the design tokens.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.pink,
        selectionColor: AppColors.pink.withValues(alpha: isDark ? 0.35 : 0.22),
        selectionHandleColor: AppColors.pink,
      ),

      // Violet thumb that brightens to pink on hover.
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.dragged)
              ? AppColors.pink
              : p.scrollThumb,
        ),
        trackColor: WidgetStatePropertyAll(Colors.transparent),
        radius: const Radius.circular(4),
        thickness: const WidgetStatePropertyAll(8),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.txt2,
          hoverColor: p.surface3,
          highlightColor: AppColors.pink.withValues(alpha: 0.08),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brandInk,
          textStyle: _body(p.brandInk, size: 13, weight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.txt,
          side: BorderSide(color: p.line2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rSm)),
          textStyle: _body(p.txt, size: 13, weight: FontWeight.w700),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rSm)),
          textStyle: _body(Colors.white, size: 13, weight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData darkTheme() => _build(VistarPalette.dark);

  static ThemeData lightTheme() => _build(VistarPalette.light);

  /// Bricolage Grotesque, for one-off display text outside the [TextTheme] —
  /// KPI numbers and the like.
  static TextStyle display(
    Color color, {
    required double size,
    FontWeight weight = FontWeight.w800,
    double letterSpacing = -0.4,
    double? height,
  }) =>
      _display(color, size: size, weight: weight, letterSpacing: letterSpacing, height: height);

  /// Manrope, for one-off body text outside the [TextTheme].
  static TextStyle body(
    Color color, {
    required double size,
    FontWeight weight = FontWeight.w500,
    double letterSpacing = 0.1,
    double? height,
  }) =>
      _body(color, size: size, weight: weight, letterSpacing: letterSpacing, height: height);
}
