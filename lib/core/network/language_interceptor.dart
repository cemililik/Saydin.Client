import 'package:dio/dio.dart';
import 'package:saydin/core/network/locale_provider.dart';

/// Her API isteğine `Accept-Language` header'ı ekleyen interceptor.
///
/// Dil kodunu DI ile enjekte edilen [LocaleProvider]'dan okur; uygulama dili
/// değiştiğinde `SettingsCubit` aynı [LocaleProvider] instance'ını günceller.
class LanguageInterceptor extends Interceptor {
  final LocaleProvider _localeProvider;

  LanguageInterceptor(this._localeProvider);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _localeProvider.localeCode;
    handler.next(options);
  }
}
