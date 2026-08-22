import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Vistar Brand Ribbon Palette (Exact Token Definitions)
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

  // Vistar Signature Ribbon Gradient (115deg verbatim)
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
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient ribbonSoftGradient = LinearGradient(
    colors: [
      Color(0xE69B30C9),
      Color(0xE6E0218A),
      Color(0xE6F0480C),
      Color(0xE6F0C000),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Near-black Premium Dark Surfaces
  static const Color bg = Color(0xFF070611);
  static const Color bg2 = Color(0xFF0B0A18);
  static const Color surface = Color(0xFF110F1E);
  static const Color surface2 = Color(0xFF16142A);
  static const Color surface3 = Color(0xFF1D1A33);

  // Hairline Lines & Borders
  static const Color line = Color(0x14FFFFFF); // rgba(255,255,255,.08)
  static const Color line2 = Color(0x21FFFFFF); // rgba(255,255,255,.13)
  static const Color lineHighlight = Color(0x33E0218A);

  // Typography Scale
  static const Color txt = Color(0xFFF2EEFB);
  static const Color txt2 = Color(0xFFB9B2D6);
  static const Color txt3 = Color(0xFF7E769B);

  // Status Indicators
  static const Color ok = Color(0xFF34D399);
  static const Color warn = Color(0xFFFBBF24);
  static const Color bad = Color(0xFFFB6F84);
  static const Color info = Color(0xFF5BA8FF);

  // Translucent Status Tints
  static const Color okTint = Color(0x2434D399);
  static const Color warnTint = Color(0x24FBBF24);
  static const Color dangerTint = Color(0x24FB6F84);
  static const Color infoTint = Color(0x245BA8FF);
  static const Color purpleTint = Color(0x2E9B30C9);

  // Backward Compatibility Tokens
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
  static const Color danger = bad;
}

extension BuildContextThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary => isDark ? AppColors.txt : const Color(0xFF0F172A);
  Color get textSecondary => isDark ? AppColors.txt2 : const Color(0xFF475569);
  Color get textMuted => isDark ? AppColors.txt3 : const Color(0xFF64748B);
  Color get bgSurfaceElevated => isDark ? AppColors.surface2 : const Color(0xFFF8FAFC);
  Color get borderLine => isDark ? AppColors.line : const Color(0xFFCBD5E1);
}
