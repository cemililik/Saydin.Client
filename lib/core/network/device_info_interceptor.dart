import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Her istekte cihaz ve uygulama bilgisi header'larını ekler.
/// Backend activity logging sistemi bu bilgileri kullanır.
///
/// **PII minimizasyonu (F-14-10):** `Platform.operatingSystemVersion`
/// ham çıktısı iOS'ta build numarası ve Darwin kernel sürümü dahil 80+
/// karakter olabilir (örn. `"Version 18.6 (Build 22G5072a) Darwin Kernel
/// Version 24.6.0..."`). Bu, fingerprinting riski yaratır ve KVKK Madde
/// 12 minimizasyon ilkesine aykırıdır. Sadece major.minor (`"18.6"`)
/// gönderilir.
class DeviceInfoInterceptor extends Interceptor {
  final String _os;
  final String _osVersion;
  final String _appVersion;

  DeviceInfoInterceptor(PackageInfo packageInfo)
    : _os = Platform.operatingSystem,
      _osVersion = minimizeOsVersion(Platform.operatingSystemVersion),
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Device-OS'] = _os;
    options.headers['X-Device-OS-Version'] = _osVersion;
    options.headers['X-App-Version'] = _appVersion;
    handler.next(options);
  }

  /// Ham OS version string'inden major.minor formatına indirir.
  ///
  /// Örnekler:
  /// - iOS: `"Version 18.6 (Build 22G5072a) Darwin Kernel..."` → `"18.6"`
  /// - Android: `"15"` → `"15"`, `"13.0"` → `"13.0"`, `"14 (Q)"` → `"14"`
  /// - macOS: `"Version 14.5 (Build 23F79)"` → `"14.5"`
  ///
  /// Match yoksa `"unknown"` döner — ham veri ASLA propagate edilmez.
  @visibleForTesting
  static String minimizeOsVersion(String raw) {
    final match = RegExp(r'(\d+)(?:\.(\d+))?').firstMatch(raw);
    if (match == null) return 'unknown';
    final major = match.group(1);
    if (major == null) return 'unknown';
    final minor = match.group(2);
    return minor != null ? '$major.$minor' : major;
  }
}
