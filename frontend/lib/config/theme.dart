import 'package:flutter/material.dart';

class AppTheme {
  // --- Velocity Signature Palette (Inspired by Modern High-End Dark UI) ---
  static const Color velocityLime = Color(0xFFCEFA2B); // Signature Electric Lime
  static const Color velocityLimeBright = Color(0xFFD6FF38);
  static const Color velocityLimeSoft = Color(0xFFE9FDC7);
  static const Color velocityLimeDim = Color(0xFFAFD61F);
  
  static const Color velocityAmber = Color(0xFFFFB300); // Warm Gold / Amber Accent
  static const Color velocityAmberSoft = Color(0xFFFFF3D6);
  static const Color velocityAccentBlue = Color(0xFF2979FF); // Electric Tech Blue
  static const Color velocityAccentCoral = Color(0xFFFF5252); // Punchy Coral Accent
  
  // Smooth Titanium Slate & Obsidian (Deep, Modern Dark Palette)
  static const Color velocityDark = Color(0xFF0F1218); // Deep Obsidian Charcoal
  static const Color velocityDarkSurface = Color(0xFF161B26); // Elevated Titanium Dark Surface
  static const Color velocityDarkBorder = Color(0xFF273142); // Refined Slate Dark Border
  static const Color velocityDarkLight = Color(0xFF303B4D); // Soft Slate Pill / Badge
  
  // Forest Noir Palette & Gradient
  static const Color forestNoirDark = Color(0xFF02060E); // Deep Midnight Noir (#02060E)
  static const Color forestNoirGreen = Color(0xFF007D10); // Rich Forest Emerald (#007D10)

  static const LinearGradient forestNoirGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      forestNoirDark,
      forestNoirGreen,
    ],
  );

  // Modern Dark Canvas & Surfaces
  static const Color velocityBackground = forestNoirDark; // Forest Noir Midnight Canvas
  static const Color velocitySurface = Color(0xFF141822); // Titanium Slate Elevated Surface
  static const Color velocitySurfaceMuted = Color(0xFF1B212E); // Deep Slate Muted Surface (Inputs/Chips)
  static const Color velocityBorder = Color(0xFF232C3A); // Subtle Crisp Border
  
  // High-Contrast Modern Typography
  static const Color velocityTextPrimary = Color(0xFFF1F5F9); // Crisp Off-White Primary
  static const Color velocityTextSecondary = Color(0xFF94A3B8); // Smooth Slate Grey Secondary
  static const Color velocityTextMuted = Color(0xFF64748B); // Soft Slate Muted Text

  // Backward compatibility aliases
  static const Color primary = velocityLime;
  static const Color primaryVariant = velocityLimeBright;
  static const Color secondary = velocityDarkSurface;
  static const Color secondaryAccent = velocityAmber;
  static const Color accent = velocityAccentBlue;
  static const Color background = velocityBackground;
  static const Color surface = velocitySurface;
  static const Color surfaceVariant = velocitySurfaceMuted;
  static const Color textPrimary = velocityTextPrimary;
  static const Color textSecondary = velocityTextSecondary;
  static const Color divider = velocityBorder;

  /// Modern High-End Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: forestNoirDark,
      primaryColor: velocityLime,
      colorScheme: const ColorScheme.dark(
        primary: velocityLime,
        secondary: velocityLimeBright,
        surface: velocitySurface,
        surfaceContainerHighest: velocitySurfaceMuted,
        onPrimary: velocityDark,
        onSecondary: velocityDark,
        onSurface: velocityTextPrimary,
        outline: velocityBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
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
      dialogTheme: DialogThemeData(
        backgroundColor: velocitySurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: velocityBorder, width: 1.2),
        ),
        titleTextStyle: const TextStyle(
          color: velocityTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: velocityTextSecondary,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: velocitySurface,
        modalBackgroundColor: velocitySurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: velocityTextPrimary,
          side: const BorderSide(color: velocityBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: velocitySurfaceMuted,
        hintStyle: const TextStyle(color: velocityTextMuted),
        labelStyle: const TextStyle(color: velocityTextSecondary),
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
          borderSide: const BorderSide(color: velocityLime, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      dividerTheme: const DividerThemeData(
        color: velocityBorder,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: velocityLime,
        unselectedItemColor: velocityTextMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Default application theme (alias to darkTheme for unified dark aesthetic)
  static ThemeData get lightTheme => darkTheme;
}
