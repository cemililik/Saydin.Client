import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/network/device_info_interceptor.dart';

void main() {
  group('DeviceInfoInterceptor.minimizeOsVersion', () {
    test('iOS ham string\'i major.minor\'a indirir', () {
      const raw = 'Version 18.6 (Build 22G5072a) Darwin Kernel Version 24.6.0';
      expect(DeviceInfoInterceptor.minimizeOsVersion(raw), '18.6');
    });

    test('Android sade sürüm korunur', () {
      expect(DeviceInfoInterceptor.minimizeOsVersion('15'), '15');
      expect(DeviceInfoInterceptor.minimizeOsVersion('13.0'), '13.0');
    });

    test('Android codename ek bilgisi soyulur', () {
      expect(DeviceInfoInterceptor.minimizeOsVersion('14 (Q)'), '14');
    });

    test('macOS ham string\'i major.minor\'a indirir', () {
      expect(
        DeviceInfoInterceptor.minimizeOsVersion('Version 14.5 (Build 23F79)'),
        '14.5',
      );
    });

    test('match yoksa "unknown" döner', () {
      expect(DeviceInfoInterceptor.minimizeOsVersion(''), 'unknown');
      expect(DeviceInfoInterceptor.minimizeOsVersion('???'), 'unknown');
    });
  });
}
