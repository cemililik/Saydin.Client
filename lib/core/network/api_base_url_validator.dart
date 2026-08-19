import 'package:flutter/foundation.dart';

/// `--dart-define=API_BASE_URL=<url>` ile geçilen base URL'in güvenlik ve
/// format açısından doğrulanması.
///
/// Release modunda `https://` zorunludur — düz HTTP ile gönderilen istekler
/// MITM saldırılarına açıktır ve KVKK Madde 12 (veri güvenliği) ile App Store
/// / Play Store iletim güvenliği kurallarını ihlal eder.
/// Release/profile build'lerde yalnız HTTPS ve default port kabul edilir.
/// Kalıcı production/staging host allowlist'i, onaylı origin kararıyla birlikte
/// ele alınacaktır; bu validator doğrulanmamış bir hostname uydurmaz.
///
/// Debug modunda `http://` yalnızca yerel geliştirme host'larına izin verilir
/// (`localhost`, `127.0.0.1`, `10.0.2.2` — Android emulator host loopback).
/// Tüneller ve LAN servisleri HTTPS kullanmak zorundadır. Böylece Dart
/// doğrulaması, Android debug network-security allowlist'i ile aynı sözleşmeyi
/// uygular; platformlardan birinde çalışan cleartext URL diğerinde sessizce
/// kırılmaz.
class ApiBaseUrlValidator {
  const ApiBaseUrlValidator._();

  /// Debug modda cleartext'e izin verilen host pattern'leri.
  static const _devCleartextHosts = <String>{
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  };

  /// `baseUrl`'i doğrular. Başarısızlıkta `StateError` fırlatır — `assert`
  /// release build'te derlenmez, dolayısıyla fail-loud doğrulama
  /// `StateError` ile yapılmalıdır.
  ///
  /// Build modu (`kReleaseMode`/`kProfileMode`) [validateForMode]'a delege
  /// edilir; `flutter test` debug modda koştuğu için release/profile
  /// cleartext-reddi dalı ancak [validateForMode] ile test edilebilir.
  static void validate(String baseUrl) => validateForMode(
    baseUrl,
    isRelease: kReleaseMode,
    isProfile: kProfileMode,
  );

  /// [validate]'in mod-bağımsız çekirdeği. `isRelease`/`isProfile` enjekte
  /// edilebilir olduğu için release/profile cleartext-reddi testlerden
  /// doğrulanabilir (debug test runner'ında bu dallar normalde erişilemez).
  @visibleForTesting
  static void validateForMode(
    String baseUrl, {
    required bool isRelease,
    required bool isProfile,
  }) {
    if (baseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL dart-define is required. '
        'Pass --dart-define=API_BASE_URL=https://<host>',
      );
    }

    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL is not a valid absolute URL: $baseUrl');
    }
    if (uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw StateError(
        'API_BASE_URL must be an origin-only URL without user info, path, '
        'query, or fragment. Got: $baseUrl',
      );
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') {
      throw StateError(
        'API_BASE_URL scheme must be https or http; got: $scheme',
      );
    }

    final host = uri.host.toLowerCase();
    if (scheme == 'https') {
      if ((isRelease || isProfile) && uri.port != 443) {
        throw StateError(
          'API_BASE_URL must use the default HTTPS port in non-debug builds. '
          'Got: ${uri.port}',
        );
      }
      return;
    }

    // HTTP — sadece debug mod + tanımlı dev host'lar. Profile build
    // de production'a yakın (release optimizasyonları + observatory);
    // cleartext oraya da sızdırmamak için profile de bloklanır.
    if (isRelease || isProfile) {
      throw StateError(
        'API_BASE_URL must use https in non-debug builds. Got: $baseUrl',
      );
    }

    if (!_devCleartextHosts.contains(host)) {
      throw StateError(
        'API_BASE_URL uses http but host is not on the dev cleartext '
        'allowlist (localhost / 127.0.0.1 / 10.0.2.2). Tunnels and LAN '
        'hosts must use https. Got: $baseUrl',
      );
    }
  }
}
