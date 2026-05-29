import 'dart:async';

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

  // F-05-14 / F-14-11: write çökerse üretilen ID atılmaz; aynı oturumda
  // (sonraki isteklerde) aynı ID kullanılır.
  test('write hatasında üretilen ID korunur ve sabit kalır', () async {
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenThrow(Exception('keystore unavailable'));

    final first = RequestOptions(path: '/v1/a');
    await interceptor.onRequest(first, _CapturingHandler());
    final second = RequestOptions(path: '/v1/b');
    await interceptor.onRequest(second, _CapturingHandler());

    final id = first.headers['X-Device-ID'] as String;
    expect(id, isNotEmpty);
    expect(
      second.headers['X-Device-ID'],
      id,
      reason: 'Ephemeral ID sabit kalmalı',
    );
  });

  // F-05-14 / F-14-11: storage tamamen erişilemezken paralel ilk istekler
  // AYNI ephemeral ID'yi almalı (in-flight tekilleştirme) — divergence yok.
  test('read hatasında paralel istekler aynı ephemeral ID alır', () async {
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenThrow(Exception('keystore unavailable'));

    final a = RequestOptions(path: '/v1/a');
    final b = RequestOptions(path: '/v1/b');
    await Future.wait([
      interceptor.onRequest(a, _CapturingHandler()),
      interceptor.onRequest(b, _CapturingHandler()),
    ]);

    expect(a.headers['X-Device-ID'], isNotEmpty);
    expect(a.headers['X-Device-ID'], b.headers['X-Device-ID']);
  });

  // L-2: çözümleme uçuştayken resetCache (hesap silme) araya girerse, silinmiş
  // ESKİ ID cache'e geri YAZILMAMALI (epoch guard). Sonraki istek taze ID alır.
  test(
    'reset during in-flight resolve does not repopulate cache with old id',
    () async {
      final gate = Completer<String?>();
      var reads = 0;
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) {
        reads++;
        return reads == 1 ? gate.future : Future.value('new-id');
      });
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      final first = RequestOptions(path: '/v1/first');
      final firstFuture = interceptor.onRequest(first, _CapturingHandler());

      // Hesap silme: çözümleme beklerken cache + in-flight sıfırlanır.
      interceptor.resetCache();
      // Gate'i ESKİ id ile tamamla (silinmeden önce okunmuş gibi).
      gate.complete('old-id');
      await firstFuture;

      // Sonraki istek: cache eski id ile DOLMADIĞI için taze çözümlenir → 'new-id'.
      final second = RequestOptions(path: '/v1/second');
      await interceptor.onRequest(second, _CapturingHandler());

      expect(second.headers['X-Device-ID'], 'new-id');
      expect(second.headers['X-Device-ID'], isNot('old-id'));
    },
  );
}

class _CapturingHandler extends RequestInterceptorHandler {}
