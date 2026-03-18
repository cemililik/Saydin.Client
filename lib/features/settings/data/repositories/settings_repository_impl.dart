import 'package:shared_preferences/shared_preferences.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyLanguage = 'settings_language';

  final SharedPreferencesAsync _prefs;

  SettingsRepositoryImpl(this._prefs);

  @override
  Future<AppSettings> load() async {
    final themeIndex = await _prefs.getInt(_keyThemeMode);
    final langIndex = await _prefs.getInt(_keyLanguage);
    return AppSettings(
      themeMode: themeIndex != null && themeIndex < AppThemeMode.values.length
          ? AppThemeMode.values[themeIndex]
          : AppThemeMode.system,
      language: langIndex != null && langIndex < AppLanguage.values.length
          ? AppLanguage.values[langIndex]
          : AppLanguage.system,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setInt(_keyThemeMode, settings.themeMode.index);
    await _prefs.setInt(_keyLanguage, settings.language.index);
  }
}
