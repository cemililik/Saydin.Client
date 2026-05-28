import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/network/device_id_interceptor.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;
  late DeviceIdInterceptor interceptor;

  setUp(() {
    storage = _MockSecureStorage();
    interceptor = DeviceIdInterceptor(storage);
    registerFallbackValue(RequestOptions(path: '/'));
  });

  test('İlk istekte storage\'dan device ID okunur, header eklenir', () async {
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'persisted-device-id');

    final options = RequestOptions(path: '/v1/test');
    final handler = _CapturingHandler();
    await interceptor.onRequest(options, handler);

    expect(options.headers['X-Device-ID'], 'persisted-device-id');
    verify(() => storage.read(key: 'saydin_device_id')).called(1);
  });

  test('Sonraki istek cache\'ten okunur (storage tekrar çağrılmaz)', () async {
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => 'persisted-device-id');

    await interceptor.onRequest(
      RequestOptions(path: '/v1/a'),
      _CapturingHandler(),
    );
    await interceptor.onRequest(
      RequestOptions(path: '/v1/b'),
      _CapturingHandler(),
    );

    verify(() => storage.read(key: 'saydin_device_id')).called(1);
  });

  test(
    'resetCache sonrası storage tekrar okunur (KVKK hesap silme akışı)',
    () async {
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'old-id');

      await interceptor.onRequest(
        RequestOptions(path: '/v1/first'),
        _CapturingHandler(),
      );

      // Hesap silme akışı: storage temizlendi, yeni ID üretilecek
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      interceptor.resetCache();

      final options = RequestOptions(path: '/v1/second');
      await interceptor.onRequest(options, _CapturingHandler());

      expect(
        options.headers['X-Device-ID'],
        isNot('old-id'),
        reason: 'Reset sonrası yeni UUID üretilmeli',
      );
      expect(options.headers['X-Device-ID'], isNotEmpty);
    },
  );
}

class _CapturingHandler extends RequestInterceptorHandler {}
