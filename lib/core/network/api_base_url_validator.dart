import 'package:flutter/foundation.dart';

/// `--dart-define=API_BASE_URL=<url>` ile geçilen base URL'in güvenlik ve
/// format açısından doğrulanması.
///
/// Release modunda `https://` zorunludur — düz HTTP ile gönderilen istekler
/// MITM saldırılarına açıktır ve KVKK Madde 12 (veri güvenliği) ile App Store
/// / Play Store iletim güvenliği kurallarını ihlal eder.
///
/// Debug modunda `http://` yalnızca yerel geliştirme host'larına izin verilir
/// (`localhost`, `127.0.0.1`, `10.0.2.2` — Android emulator host loopback,
/// `*.ngrok-free.app`, `*.ngrok.app`, `*.trycloudflare.com`). Bu beyaz
/// listenin amacı: dev ngrok URL'i bir typo nedeniyle üçüncü taraf domain'e
/// dönerse erken sinyal vermek.
class ApiBaseUrlValidator {
  const ApiBaseUrlValidator._();

  /// Debug modda cleartext'e izin verilen host pattern'leri.
  static const _devCleartextHosts = <String>{
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  };

  /// Debug modda cleartext'e izin verilen host suffix'leri.
  static const _devCleartextHostSuffixes = <String>[
    '.ngrok-free.app',
    '.ngrok.app',
    '.trycloudflare.com',
  ];

  /// `baseUrl`'i doğrular. Başarısızlıkta `StateError` fırlatır — `assert`
  /// release build'te derlenmez, dolayısıyla fail-loud doğrulama
  /// `StateError` ile yapılmalıdır.
  static void validate(String baseUrl) {
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

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') {
      throw StateError(
        'API_BASE_URL scheme must be https or http; got: $scheme',
      );
    }

    if (scheme == 'https') return;

    // HTTP — sadece debug mod + tanımlı dev host'lar.
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL must use https in release builds. '
        'Got: $baseUrl',
      );
    }

    final host = uri.host.toLowerCase();
    final isAllowedHost =
        _devCleartextHosts.contains(host) ||
        _devCleartextHostSuffixes.any(host.endsWith);

    if (!isAllowedHost) {
      throw StateError(
        'API_BASE_URL uses http but host is not on the dev cleartext '
        'allowlist (localhost / 10.0.2.2 / *.ngrok-free.app / '
        '*.ngrok.app / *.trycloudflare.com). Got: $baseUrl',
      );
    }
  }
}
