import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0E13);
  static const Color backgroundAlt = Color(0xFF141A22);
  static const Color surface = Color(0xFF1B212B);
  static const Color accentGold = Color(0xFFE6B15A);
  static const Color accentOrange = Color(0xFFFF8A5B);
  static const Color accentPurple = Color(0xFF8C6BFF);
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textSecondary = Color(0xFFACB7C6);
  static const Color success = Color(0xFF7EE7B7);
  static const Color error = Color(0xFFFF6B6B);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: backgroundAlt,
      primaryColor: accentPurple,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: accentPurple,
        secondary: accentGold,
        surface: surface,
        background: background,
        onPrimary: textPrimary,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundAlt,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentGold, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: accentPurple,
        labelStyle: const TextStyle(color: textPrimary),
      ),
    );
  }
}
