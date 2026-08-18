import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saydin/core/di/injection.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('invalid API URL ApiClient çözülmeden başlangıçta reddedilir', () async {
    await expectLater(
      configureDependencies(apiBaseUrlOverride: 'https://api.saydin.app/v1'),
      throwsA(isA<StateError>()),
    );

    // Validation, PackageInfo platform çağrısından ve lazy ApiClient
    // çözümlemesinden önce gerçekleşir. Böylece hatalı define ile uygulama
    // kullanıcı cihazında ilk network ekranına kadar ilerlemez.
    expect(sl.isRegistered<PackageInfo>(), isFalse);
  });
}
