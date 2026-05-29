import 'dart:ui';

/// Aktif uygulama dil kodunu (`Accept-Language`) tutan soyut sağlayıcı.
///
/// Önceden `AppLocaleHolder` global **mutable static** idi: testlerde izole
/// edilemiyor, paralel testlerde sızıntı/race üretebiliyordu ve `SettingsCubit`
/// doğrudan global state'i mutasyona uğratıyordu (F-12-17 + F-05-27). Artık
/// DI ile enjekte edilen bir arayüz: `LanguageInterceptor` okur, `SettingsCubit`
/// günceller; test sahte (fake) bir implementasyon geçer.
abstract interface class LocaleProvider {
  /// Geçerli dil kodu — `"tr"`, `"en"` veya sistem locale dil kodu.
  String get localeCode;

  /// [languageCode] → `"tr"` / `"en"` / `null` (system).
  /// `null` geldiğinde platform locale dil kodu kullanılır.
  void update(String? languageCode);
}

/// Bellek-içi tek-instance dil kodu tutucusu (DI'da `LazySingleton`).
///
/// Başlangıç değeri platform locale'inden alınır; `SettingsCubit` kullanıcı
/// tercihini yükleyince [update] ile güncellenir.
class AppLocaleHolder implements LocaleProvider {
  AppLocaleHolder();

  String _code = PlatformDispatcher.instance.locale.languageCode;

  @override
  String get localeCode => _code;

  @override
  void update(String? languageCode) {
    _code = languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  }
}
