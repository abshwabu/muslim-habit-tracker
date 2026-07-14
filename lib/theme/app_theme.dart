import 'package:flutter/material.dart';

/// Calm green / earth-tone palette for a peaceful habit-tracking feel.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF5B7C5A); // soft sage green
  static const Color _surface = Color(0xFFF5F0E8); // warm sand
  static const Color _earth = Color(0xFF8B7355); // muted brown

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: _surface,
      primary: _seed,
      secondary: _earth,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}
