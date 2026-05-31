import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:saydin/core/network/device_info_interceptor.dart';
import 'package:saydin/core/platform/platform_info.dart';

/// Sentry scope'una **PII OLMAYAN** cihaz/uygulama etiketleri ekler (F-05-07).
///
/// Amaç: crash event'lerini "hangi OS sürümünde / hangi app sürümünde
/// patlıyor?" sorusuna yanıt verecek şekilde gruplanabilir kılmak. Eklenen
/// etiketler:
/// - `os` (`ios`/`android`) ve `os_version` (yalnızca major.minor — header'la
///   AYNI minimizasyon: [DeviceInfoInterceptor.minimizeOsVersion]),
/// - `app_version` (`<version>+<build>`).
///
/// **KVKK / PII sınırı:** `X-Device-ID`, kullanıcı kimliği, IP gibi tanımlayıcı
/// veriler ASLA eklenmez ve Sentry `user` set EDİLMEZ — CLAUDE.md "device ID
/// PII'dir" kuralı. Yalnızca cihaz sınıfı/sürüm telemetrisi gönderilir.
///
/// Sentry devre dışıysa (DSN yok) `configureScope` no-op'tur — güvenle çağrılır.
Future<void> configureSentryDeviceScope({
  required PackageInfo packageInfo,
  required PlatformInfo platform,
}) async {
  await Sentry.configureScope((scope) {
    scope.setTag('os', platform.operatingSystem);
    scope.setTag(
      'os_version',
      DeviceInfoInterceptor.minimizeOsVersion(platform.operatingSystemVersion),
    );
    scope.setTag(
      'app_version',
      '${packageInfo.version}+${packageInfo.buildNumber}',
    );
  });
}
