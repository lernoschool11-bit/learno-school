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

  // ── Calm & Premium Palette ────────────────────────────────────
  static const Color oledBlack      = Color(0xFF000000);
  static const Color surfaceDark    = Color(0xFF0A0A0A);
  static const Color surfaceLight   = Color(0xFF121212);
  static const Color deepNavy       = Color(0xFF0A2342); // The "Old" calm color
  static const Color softPurple     = Color(0xFF480CA8);
  static const Color primaryColor   = deepNavy;
  static const Color accentColor    = softPurple;
  static const Color textPrimary    = Color(0xFFE0E0E0);
  static const Color textSecondary  = Color(0xFF808080);
  static const Color textHint       = Color(0xFF505050);
  static const Color dividerColor   = Color(0xFF1A1A1A);
  static const Color errorRed       = Color(0xFFFF2D55);
  static const Color offWhite       = Color(0xFFFAF9F6); // Matte white for icons
  static const Color searchFieldBg  = Color(0xFF1A1A1A);

  // ── Gradient helpers ──────────────────────────────────────────
  static const LinearGradient neonGradient = LinearGradient(
    colors: [softPurple, deepNavy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkButtonGradient = LinearGradient(
    colors: [Color(0xFF1A0A2E), oledBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF0A0A0A), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient xpGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF0088FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ── Glassmorphism ─────────────────────────────────────────────
  static BoxDecoration glassDecoration({double opacity = 0.1, double blur = 10.0}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }

  // ── Shadow presets ────────────────────────────────────────────
  static List<BoxShadow> get primaryColorGlow => [
    BoxShadow(
      color: primaryColor.withAlpha(60),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get accentColorGlow => [
    BoxShadow(
      color: accentColor.withAlpha(60),
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
        primary: deepNavy,
        secondary: softPurple,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
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
        iconTheme: IconThemeData(color: offWhite),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shadowColor: primaryColor.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // Search bar and Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchFieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), // Fully rounded
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary),
        prefixIconColor: primaryColor,
        suffixIconColor: textSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dividerColor, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
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
      iconTheme: const IconThemeData(color: primaryColor, size: 24),

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
        selectedItemColor: primaryColor,
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
        backgroundColor: primaryColor,
        foregroundColor: oledBlack,
        elevation: 8,
      ),

      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceDark,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textHint,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: primaryColor.withAlpha(40),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
