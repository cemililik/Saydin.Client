import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, system }

enum AppLanguage { tr, en, system }

class AppSettings extends Equatable {
  final AppThemeMode themeMode;
  final AppLanguage language;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.system,
  });

  AppSettings copyWith({AppThemeMode? themeMode, AppLanguage? language}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [themeMode, language];
}
