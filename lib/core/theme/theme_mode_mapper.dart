import 'package:flutter/material.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';

ThemeMode toFlutterThemeMode(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}
