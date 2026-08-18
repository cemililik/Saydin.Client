import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saydin/core/network/api_client.dart';
import 'package:saydin/core/network/locale_provider.dart';
import 'package:saydin/core/platform/platform_info.dart';

class _FakePlatformInfo implements PlatformInfo {
  @override
  String get operatingSystem => 'ios';

  @override
  String get operatingSystemVersion => '18.0';
}

class _FakeLocaleProvider implements LocaleProvider {
  @override
  String get localeCode => 'tr';

  @override
  void update(String? languageCode) {}
}

void main() {
  test(
    'network timeout sözleşmesi connect/send/receive için explicit 15 sn',
    () {
      final client = ApiClient(
        baseUrl: 'https://api.saydin.app',
        packageInfo: PackageInfo(
          appName: 'Saydın',
          packageName: 'com.saydin.saydin',
          version: '1.0.0',
          buildNumber: '1',
        ),
        platformInfo: _FakePlatformInfo(),
        localeProvider: _FakeLocaleProvider(),
        storage: const FlutterSecureStorage(),
      );

      expect(client.dio.options.connectTimeout, const Duration(seconds: 15));
      expect(client.dio.options.sendTimeout, const Duration(seconds: 15));
      expect(client.dio.options.receiveTimeout, const Duration(seconds: 15));
    },
  );
}
