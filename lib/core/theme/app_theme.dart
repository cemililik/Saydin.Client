import 'package:flutter/material.dart';
import 'package:saydin/core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _seedColor = AppColors.primary;

  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      elevation: 8,
    ),
  );

  static final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.grey.shade900,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      elevation: 8,
    ),
  );
}
