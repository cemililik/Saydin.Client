import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdInterceptor extends Interceptor {
  static const _storageKey = 'saydin_device_id';
  final FlutterSecureStorage _storage;

  DeviceIdInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final deviceId = await _getOrCreateDeviceId();
    options.headers['X-Device-ID'] = deviceId;
    handler.next(options);
  }

  Future<String> _getOrCreateDeviceId() async {
    var deviceId = await _storage.read(key: _storageKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await _storage.write(key: _storageKey, value: deviceId);
    }
    return deviceId;
  }
}
