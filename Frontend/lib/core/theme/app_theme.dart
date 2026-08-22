import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData darkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      primaryColor: AppColors.ribbonPink,
      cardColor: AppColors.bgSurface,
      dividerColor: AppColors.line,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.ribbonPink,
        secondary: AppColors.ribbonOrange,
        surface: AppColors.bgSurface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.bricolageGrotesque(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        labelSmall: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        contentPadding: const EdgeInsets.all(14),
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
          borderSide: const BorderSide(color: AppColors.ribbonPink, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }

  static ThemeData lightTheme() {
    const lightBg = Color(0xFFF1F5F9);
    const lightSurface = Color(0xFFFFFFFF);
    const lightTextPrimary = Color(0xFF0F172A);
    const lightTextSecondary = Color(0xFF475569);
    const lightBorder = Color(0xFFCBD5E1);

    return ThemeData.light().copyWith(
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
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        headlineLarge: GoogleFonts.bricolageGrotesque(
          color: lightTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          color: lightTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          color: lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          color: lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: const TextStyle(
          color: lightTextSecondary,
          fontSize: 13,
        ),
        labelSmall: const TextStyle(
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
        labelStyle: const TextStyle(color: lightTextSecondary, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      ),
    );
  }
}
