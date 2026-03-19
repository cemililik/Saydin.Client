import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Her istekte cihaz ve uygulama bilgisi header'larını ekler.
/// Backend activity logging sistemi bu bilgileri kullanır.
class DeviceInfoInterceptor extends Interceptor {
  final PackageInfo _packageInfo;

  DeviceInfoInterceptor(this._packageInfo);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Device-OS'] = Platform.operatingSystem;
    options.headers['X-Device-OS-Version'] = Platform.operatingSystemVersion;
    options.headers['X-App-Version'] =
        '${_packageInfo.version}+${_packageInfo.buildNumber}';
    handler.next(options);
  }
}
