import 'dart:io' show Platform;

/// İşletim sistemi bilgisine soyut erişim.
///
/// `dart:io`'yu **tek noktada** izole eder: network/interceptor katmanı bunu
/// import etmek zorunda kalmaz (CLAUDE.md "BLoC içinde `dart:io` YASAK" ve
/// genel olarak transport katmanının platforma sızmaması ilkesi — F-05-06)
/// ve birim testlerde sahte bir implementasyonla değiştirilebilir.
abstract interface class PlatformInfo {
  /// `Platform.operatingSystem` semantiği: `'ios'`, `'android'`, ...
  String get operatingSystem;

  /// Ham OS sürüm string'i (`Platform.operatingSystemVersion`).
  /// PII minimizasyonu tüketici tarafında yapılır
  /// (bkz. [DeviceInfoInterceptor] `minimizeOsVersion`).
  String get operatingSystemVersion;
}

/// `dart:io.Platform` tabanlı varsayılan implementasyon (iOS / Android).
class SystemPlatformInfo implements PlatformInfo {
  const SystemPlatformInfo();

  @override
  String get operatingSystem => Platform.operatingSystem;

  @override
  String get operatingSystemVersion => Platform.operatingSystemVersion;
}
