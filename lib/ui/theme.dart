import 'package:flutter/material.dart';

/// Design tokens: paper-white with deep blue chrome (the colour of the icon's
/// background) and one amber accent for the chosen answer.
abstract final class AppColors {
  static const navy = Color(0xFF1A4C8B);
  static const amber = Color(0xFFE39A1C);
  static const correct = Color(0xFF1E7B45);
  static const incorrect = Color(0xFFB3261E);
  static const flagged = Color(0xFFD97F00);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light ? AppColors.navy : scheme.surface,
        foregroundColor: brightness == Brightness.light ? Colors.white : scheme.onSurface,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      ),
    );
  }
}
