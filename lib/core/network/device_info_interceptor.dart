import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Her istekte cihaz ve uygulama bilgisi header'larını ekler.
/// Backend activity logging sistemi bu bilgileri kullanır.
class DeviceInfoInterceptor extends Interceptor {
  final String _os;
  final String _osVersion;
  final String _appVersion;

  DeviceInfoInterceptor(PackageInfo packageInfo)
    : _os = Platform.operatingSystem,
      _osVersion = Platform.operatingSystemVersion,
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Device-OS'] = _os;
    options.headers['X-Device-OS-Version'] = _osVersion;
    options.headers['X-App-Version'] = _appVersion;
    handler.next(options);
  }
}
