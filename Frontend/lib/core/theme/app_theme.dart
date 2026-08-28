import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_tokens.dart';

class AppTheme {
  AppTheme._();

  static const String fontBody = 'Plus Jakarta Sans';
  static const String fontDisplay = 'Bricolage Grotesque';

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: fontBody,
      scaffoldBackgroundColor: AppColors.bg,
      primaryColor: AppColors.pink,
      cardColor: AppColors.surface,
      dividerColor: AppColors.line,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.pink,
        secondary: AppColors.orange,
        surface: AppColors.surface,
        onSurface: AppColors.txt,
        error: AppColors.bad,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: fontDisplay,
          color: AppColors.txt,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontDisplay,
          color: AppColors.txt,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontDisplay,
          color: AppColors.txt,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: fontDisplay,
          color: AppColors.txt,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontBody,
          color: AppColors.txt,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontBody,
          color: AppColors.txt2,
          fontSize: 13,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          fontFamily: fontBody,
          color: AppColors.txt3,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: const BorderSide(color: Color(0x99E0218A), width: 1.5),
        ),
        labelStyle: const TextStyle(fontFamily: fontBody, color: AppColors.txt2, fontSize: 13),
        hintStyle: const TextStyle(fontFamily: fontBody, color: AppColors.txt3, fontSize: 13),
      ),
    );
  }

  static ThemeData lightTheme() {
    const lightBg = Color(0xFFF1F5F9);
    const lightSurface = Color(0xFFFFFFFF);
    const lightTextPrimary = Color(0xFF0F172A);
    const lightTextSecondary = Color(0xFF475569);
    const lightBorder = Color(0xFFCBD5E1);

    return ThemeData(
      brightness: Brightness.light,
      fontFamily: fontBody,
      scaffoldBackgroundColor: lightBg,
      primaryColor: AppColors.ribbonPink,
      cardColor: lightSurface,
      dividerColor: lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ribbonPink,
        secondary: AppColors.ribbonOrange,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: AppColors.danger,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: fontDisplay,
          color: lightTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontDisplay,
          color: lightTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontDisplay,
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          fontFamily: fontDisplay,
          color: lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          fontFamily: fontBody,
          color: lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontFamily: fontBody,
          color: lightTextSecondary,
          fontSize: 13,
        ),
        labelSmall: TextStyle(
          fontFamily: fontBody,
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rSm),
          borderSide: const BorderSide(color: AppColors.ribbonPink, width: 1.5),
        ),
        labelStyle: const TextStyle(fontFamily: fontBody, color: lightTextSecondary, fontSize: 13),
        hintStyle: const TextStyle(fontFamily: fontBody, color: Color(0xFF94A3B8), fontSize: 13),
      ),
    );
  }
}
