import 'package:flutter/material.dart';

import '../theme/vistar_palette.dart';

/// Vistar brand constants.
///
/// Only values that are **identical in light and dark** live here as statics:
/// the ribbon palette, and the vivid status colours used as *fills* (snackbar
/// grounds, dots, progress arcs) where the foreground is always white.
///
/// Anything that must change with the active brightness — surfaces, hairlines,
/// the text ramp, and status colours used as *ink* — lives on [VistarPalette]
/// and is read through the [BuildContextThemeX] getters on `context`.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand ribbon — the signature accent, constant across both modes.
  // ---------------------------------------------------------------------------
  static const Color purple = Color(0xFF7A1FB0);
  static const Color violet = Color(0xFF9B30C9);
  static const Color magenta = Color(0xFFC018C0);
  static const Color pink = Color(0xFFE0218A);
  static const Color red = Color(0xFFC8102E);
  static const Color orangeRed = Color(0xFFF0480C);
  static const Color orange = Color(0xFFF06000);
  static const Color amber = Color(0xFFF0C000);
  static const Color yellow = Color(0xFFF0E060);
  static const Color cream = Color(0xFFFFF6CC);

  /// The 115deg Vistar ribbon, verbatim from the design tokens.
  ///
  /// `begin`/`end` reproduce a 115deg CSS sweep: mostly left-to-right with a
  /// slight downward tilt.
  static const LinearGradient ribbonGradient = LinearGradient(
    colors: [
      Color(0xFF7A1FB0),
      Color(0xFFB81FB8),
      Color(0xFFE0218A),
      Color(0xFFD11630),
      Color(0xFFF0480C),
      Color(0xFFF06000),
      Color(0xFFF0C000),
      Color(0xFFF7EE9A),
    ],
    stops: [0.0, 0.22, 0.40, 0.56, 0.70, 0.80, 0.92, 1.0],
    begin: Alignment(-1.0, -0.42),
    end: Alignment(1.0, 0.42),
  );

  static const LinearGradient ribbonSoftGradient = LinearGradient(
    colors: [
      Color(0xE69B30C9),
      Color(0xE6E0218A),
      Color(0xE6F0480C),
      Color(0xE6F0C000),
    ],
    begin: Alignment(-1.0, -0.42),
    end: Alignment(1.0, 0.42),
  );

  /// Vertical ribbon, for the 3px active-nav bar and section accents.
  static const LinearGradient ribbonVertical = LinearGradient(
    colors: [
      Color(0xFF7A1FB0),
      Color(0xFFE0218A),
      Color(0xFFF0480C),
      Color(0xFFF0C000),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ---------------------------------------------------------------------------
  // Vivid status fills. White-on-these is legible in either mode, so these stay
  // constant. For status *ink* (text, icons, borders) use `context.okInk` etc.
  // ---------------------------------------------------------------------------
  static const Color ok = Color(0xFF34D399);
  static const Color warn = Color(0xFFFBBF24);
  static const Color bad = Color(0xFFFB6F84);
  static const Color info = Color(0xFF5BA8FF);
  static const Color danger = bad;

  // ---------------------------------------------------------------------------
  // Dark-scale statics.
  //
  // These remain for the handful of surfaces that are dark in *both* themes —
  // camera scanner viewfinders, print previews, splash. Do not reach for them
  // for ordinary chrome; use `context.*` so light mode stays correct.
  // ---------------------------------------------------------------------------
  static const Color bg = Color(0xFF070611);
  static const Color bg2 = Color(0xFF0B0A18);
  static const Color surface = Color(0xFF110F1E);
  static const Color surface2 = Color(0xFF16142A);
  static const Color surface3 = Color(0xFF1D1A33);
  static const Color line = Color(0x14FFFFFF);
  static const Color line2 = Color(0x21FFFFFF);
  static const Color txt = Color(0xFFF2EEFB);
  static const Color txt2 = Color(0xFFB9B2D6);
  static const Color txt3 = Color(0xFF7E769B);

  static const Color okTint = Color(0x2434D399);
  static const Color warnTint = Color(0x24FBBF24);
  static const Color dangerTint = Color(0x24FB6F84);
  static const Color infoTint = Color(0x245BA8FF);
  static const Color purpleTint = Color(0x2E9B30C9);
  static const Color lineHighlight = Color(0x33E0218A);

  // Legacy aliases kept so existing call sites keep compiling.
  static const Color bgDark = bg;
  static const Color bgSurface = surface;
  static const Color bgSurfaceElevated = surface2;
  static const Color bgSurfaceHighlight = surface3;
  static const Color ribbonPink = pink;
  static const Color ribbonOrange = orange;
  static const Color ribbonAmber = amber;
  static const Color ribbonPurple = violet;
  static const Color textPrimary = txt;
  static const Color textSecondary = txt2;
  static const Color textMuted = txt3;
}

/// Theme-aware token access.
///
/// Every getter resolves against the [VistarPalette] on the active theme, so
/// the same widget code renders correctly in light and dark.
extension BuildContextThemeX on BuildContext {
  VistarPalette get vistar => VistarPalette.of(this);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Grounds
  Color get bgCanvas => vistar.bg;
  Color get bgPanel => vistar.bg2;
  Color get bgSurface => vistar.surface;
  Color get bgSurfaceElevated => vistar.surface2;
  Color get bgSurfaceHighlight => vistar.surface3;

  // Text ramp
  Color get textPrimary => vistar.txt;
  Color get textSecondary => vistar.txt2;
  Color get textMuted => vistar.txt3;

  // Hairlines
  Color get borderLine => vistar.line;
  Color get borderLineStrong => vistar.line2;

  // Status ink — legible as text/icons on this brightness.
  Color get okInk => vistar.ok;
  Color get warnInk => vistar.warn;
  Color get dangerInk => vistar.bad;
  Color get infoInk => vistar.info;

  // Status grounds
  Color get okTint => vistar.okTint;
  Color get warnTint => vistar.warnTint;
  Color get dangerTint => vistar.badTint;
  Color get infoTint => vistar.infoTint;
  Color get brandTint => vistar.brandTint;
  Color get neutralTint => vistar.neutralTint;

  /// Brand pink darkened for light mode so it stays readable as text.
  Color get brandInk => vistar.brandInk;

  Color get shadowSoft => vistar.shadowColor;
}
