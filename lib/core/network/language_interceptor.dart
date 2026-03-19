import 'dart:ui';

import 'package:dio/dio.dart';

/// Her API isteğine Accept-Language header'ı ekleyen interceptor.
/// Uygulama dili değiştiğinde [AppLocaleHolder.update] çağrılarak güncellenir.
class LanguageInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = AppLocaleHolder.code;
    handler.next(options);
  }
}

/// Uygulama genelinde aktif dil kodunu tutan basit holder.
/// SettingsCubit dil değiştiğinde [update] çağırır.
class AppLocaleHolder {
  static String _code = PlatformDispatcher.instance.locale.languageCode;

  static String get code => _code;

  /// [languageCode] → "tr", "en" veya null (system).
  /// null geldiğinde platform locale kullanılır.
  static void update(String? languageCode) {
    _code = languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  }
}
