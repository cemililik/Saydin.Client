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
    return AppSettings(
      themeMode: await _loadEnum(
        _keyThemeMode,
        AppThemeMode.values,
        AppThemeMode.system,
      ),
      language: await _loadEnum(
        _keyLanguage,
        AppLanguage.values,
        AppLanguage.system,
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    // Kararlı `enum.name` (string) sakla — ordinal `index` DEĞİL. Enum
    // değerleri yeniden sıralanırsa eski index'ler sessizce yanlış değere
    // map'lenirdi (örn. `dark` → `light`). `name` refactor'a dayanıklıdır.
    await _prefs.setString(_keyThemeMode, settings.themeMode.name);
    await _prefs.setString(_keyLanguage, settings.language.name);
  }

  /// Enum'u `name` ile okur; bilinmeyen/eksik değerde [fallback].
  /// Geriye uyumluluk: eski sürüm `index` (int) sakladıysa onu okuyup
  /// hemen `name` formatında yeniden yazar (tek seferlik migration).
  Future<T> _loadEnum<T extends Enum>(
    String key,
    List<T> values,
    T fallback,
  ) async {
    String? name;
    try {
      name = await _prefs.getString(key);
    } catch (_) {
      // Anahtar eski int formatında saklı — getString tip uyuşmazlığı atar.
      name = null;
    }
    if (name != null) {
      return values.firstWhere((e) => e.name == name, orElse: () => fallback);
    }
    final legacyIndex = await _prefs.getInt(key);
    if (legacyIndex != null &&
        legacyIndex >= 0 &&
        legacyIndex < values.length) {
      final migrated = values[legacyIndex];
      await _prefs.setString(key, migrated.name);
      return migrated;
    }
    return fallback;
  }
}
