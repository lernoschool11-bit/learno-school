import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────
/// Learno – OLED Dark Theme  (Neon Cyan + Neon Magenta)
/// ──────────────────────────────────────────────────────────────
/// Drop this into `main.dart` via:
///   theme: AppTheme.darkTheme,
///
/// IMPORTANT: This file only defines visual tokens.
///            It does NOT touch any business logic.
/// ──────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._(); // prevent instantiation

  // ── Core palette ──────────────────────────────────────────────
  static const Color oledBlack      = Color(0xFF000000);
  static const Color surfaceDark    = Color(0xFF121212);
  static const Color surfaceLight   = Color(0xFF1A1A1A);
  static const Color cardDark       = Color(0xFF1E1E1E);
  static const Color neonCyan       = Color(0xFF00FFFF);
  static const Color neonMagenta    = Color(0xFFFF00FF);
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFFB0B0B0);
  static const Color textHint       = Color(0xFF707070);
  static const Color dividerColor   = Color(0xFF2A2A2A);
  static const Color errorRed       = Color(0xFFFF4C6A);

  // ── Gradient helpers ──────────────────────────────────────────
  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonCyan, neonMagenta],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFF0D2B3E), Color(0xFF1A0A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [neonCyan, Color(0xFF0080FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Shadow presets ────────────────────────────────────────────
  static List<BoxShadow> get neonCyanGlow => [
    BoxShadow(
      color: neonCyan.withAlpha(60),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get neonMagentaGlow => [
    BoxShadow(
      color: neonMagenta.withAlpha(60),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Roboto',

      // Scaffold / background
      scaffoldBackgroundColor: oledBlack,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        surface: oledBlack,
        primary: neonCyan,
        secondary: neonMagenta,
        error: errorRed,
        onPrimary: oledBlack,
        onSecondary: oledBlack,
        onSurface: textPrimary,
        onError: oledBlack,
        outline: dividerColor,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: oledBlack,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: neonCyan),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shadowColor: neonCyan.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: oledBlack,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 6,
          shadowColor: neonCyan.withAlpha(80),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonCyan,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          side: const BorderSide(color: neonCyan, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        hintStyle: const TextStyle(color: textHint),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: neonCyan,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: neonCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: neonCyan, size: 24),

      // Divider
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 0.5,
        space: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // Bottom navigation (fallback – the MacDock replaces this)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: neonCyan,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: dividerColor.withAlpha(80)),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonCyan,
        foregroundColor: oledBlack,
        elevation: 8,
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: neonCyan,
        linearTrackColor: surfaceDark,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: neonCyan,
        unselectedLabelColor: textHint,
        indicatorColor: neonCyan,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: neonCyan.withAlpha(40),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
