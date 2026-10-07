import 'package:flutter/material.dart';

class AppTheme {
  // --- Velocity Signature Palette (Inspired by Velocity Design) ---
  static const Color velocityLime = Color(0xFFCEFA2B); // Signature Electric Lime
  static const Color velocityLimeBright = Color(0xFFD6FF38);
  static const Color velocityLimeSoft = Color(0xFFE9FDC7);
  static const Color velocityLimeDim = Color(0xFFAFD61F);
  
  static const Color velocityAmber = Color(0xFFFFB300); // Warm Gold / Amber Accent
  static const Color velocityAmberSoft = Color(0xFFFFF3D6);
  
  // Smooth Titanium Slate & Graphite (Secondary Dark Palette - blends smoothly with Lime & Canvas)
  static const Color velocityDark = Color(0xFF20252D); // Smooth Titanium Charcoal (Secondary Dark)
  static const Color velocityDarkSurface = Color(0xFF2B323C); // Smooth Elevated Titanium Slate
  static const Color velocityDarkBorder = Color(0xFF3C4452); // Refined Slate Border
  static const Color velocityDarkLight = Color(0xFF38404E); // Soft Slate Pill / Badge
  
  static const Color velocityBackground = Color(0xFFF6F8FA); // Clean Cool-Tinted Canvas
  static const Color velocitySurface = Colors.white;
  static const Color velocitySurfaceMuted = Color(0xFFEFF2F5);
  static const Color velocityBorder = Color(0xFFE2E7ED);
  
  static const Color velocityTextPrimary = Color(0xFF1A1F26); // Deep Titanium Charcoal
  static const Color velocityTextSecondary = Color(0xFF5F6978); // Smooth Slate Grey
  static const Color velocityTextMuted = Color(0xFF8B95A4); // Soft Cool Grey

  // Backward compatibility aliases
  static const Color primary = velocityLime;
  static const Color primaryVariant = velocityLimeBright;
  static const Color secondary = velocityDark; // Secondary brand dark color
  static const Color secondaryAccent = velocityAmber;
  static const Color accent = Color(0xFF2979FF);
  static const Color background = velocityBackground;
  static const Color surface = velocitySurface;
  static const Color surfaceVariant = velocitySurfaceMuted;
  static const Color textPrimary = velocityTextPrimary;
  static const Color textSecondary = velocityTextSecondary;
  static const Color divider = velocityBorder;

  /// Signature Light Theme (Exact match for Velocity design)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: velocityBackground,
      primaryColor: velocityLime,
      colorScheme: const ColorScheme.light(
        primary: velocityLime,
        secondary: velocityDark,
        surface: velocitySurface,
        surfaceContainerHighest: velocitySurfaceMuted,
        onPrimary: velocityDark,
        onSecondary: Colors.white,
        onSurface: velocityTextPrimary,
        outline: velocityBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: velocityBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: velocityTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: velocityTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: velocitySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: velocityBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: velocityLimeBright,
          foregroundColor: velocityDark,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: velocitySurface,
        hintStyle: const TextStyle(color: velocityTextMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: velocityBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: velocityBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: velocityDark, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: velocityDark,
        unselectedItemColor: Color(0xFF5F6978),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Dark Velocity Theme (for dark mode lovers)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF13161C),
      primaryColor: velocityLime,
      colorScheme: const ColorScheme.dark(
        primary: velocityLime,
        secondary: velocityDarkSurface,
        surface: Color(0xFF1B2028),
        surfaceContainerHighest: Color(0xFF252C37),
        onPrimary: velocityDark,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF1F5F9),
        outline: Color(0xFF353E4C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF13161C),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFFF1F5F9),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B2028),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF353E4C), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: velocityLimeBright,
          foregroundColor: velocityDark,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
