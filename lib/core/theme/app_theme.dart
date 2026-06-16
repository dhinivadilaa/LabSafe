import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors (Dark Blue / Navy / Slate)
  static const Color primaryDark = Color(0xFF0F172A); // Slate 900
  static const Color primaryMid = Color(0xFF1E293B); // Slate 800
  static const Color primaryBlue = Color(0xFF2563EB); // Blue 600
  static const Color accentBlue = Color(0xFF3B82F6); // Blue 500
  static const Color accentCyan = Color(0xFF0EA5E9); // Sky 500 (replacement for Cyan)

  // Semantic/Status Colors (Lebih elegan)
  static const Color dangerRed = Color(0xFFEF4444); // Red 500
  static const Color successGreen = Color(0xFF10B981); // Emerald 500
  static const Color warningOrange = Color(0xFFF59E0B); // Amber 500

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF8FAFC); // Slate 50
  static const Color grey100 = Color(0xFFF1F5F9); // Slate 100
  static const Color grey200 = Color(0xFFE2E8F0); // Slate 200
  static const Color grey400 = Color(0xFF94A3B8); // Slate 400
  static const Color grey600 = Color(0xFF475569); // Slate 600
  static const Color grey800 = Color(0xFF1E293B); // Slate 800

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: accentBlue,
        error: dangerRed,
        surface: grey50,
      ),
      scaffoldBackgroundColor: grey50,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: grey200, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.inter(color: grey600, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: grey400, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: grey200, width: 1),
        ),
        color: white,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
