import 'package:flutter/material.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/theme/financial_colors.dart';

class AppTheme {
  AppTheme._();

  static const _seedColor = AppColors.primary;

  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [
        brightness == Brightness.dark
            ? FinancialColors.dark
            : FinancialColors.light,
      ],
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surfaceContainer,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        elevation: 8,
      ),
    );
  }
}
