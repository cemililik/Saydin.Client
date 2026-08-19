import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();

  test('iOS Debug ve Release/Profile ATS plistleri ayrı ve fail-closed', () {
    final releasePlist = read('ios/Runner/Info.plist');
    final debugPlist = read('ios/Runner/Info-Debug.plist');
    final project = read('ios/Runner.xcodeproj/project.pbxproj');

    expect(releasePlist, contains('<key>NSAppTransportSecurity</key>'));
    expect(releasePlist, isNot(contains('NSAllowsLocalNetworking')));
    expect(releasePlist, isNot(contains('NSExceptionAllowsInsecureHTTPLoads')));

    expect(debugPlist, contains('<key>NSAllowsLocalNetworking</key>'));
    expect(debugPlist, contains('<key>localhost</key>'));
    expect(debugPlist, contains('NSExceptionAllowsInsecureHTTPLoads'));

    bool configUsesPlist(String configurationId, String plist) {
      // Xcode aynı path'i geçerli biçimde tırnaklı veya tırnaksız serialize
      // edebilir. Güvenlik testi yazım stilini değil, configuration-plist
      // eşleşmesini doğrular.
      final escapedPlist = RegExp.escape(plist);
      return RegExp(
        '$configurationId /\\* .*? \\*/ = \\{.*?'
        'INFOPLIST_FILE = "?$escapedPlist"?;',
        dotAll: true,
      ).hasMatch(project);
    }

    // Runner Debug yalnız debug exception plist'ini, Profile ve Release ise
    // release-safe plist'i kullanmalıdır. Sadece iki string'in project'te
    // geçmesi bu güvenlik ayrımını kanıtlamaz.
    expect(
      configUsesPlist('97C147061CF9000F007C117D', 'Runner/Info-Debug.plist'),
      isTrue,
    );
    expect(
      configUsesPlist('249021D4217E4FDB00AE95B9', 'Runner/Info.plist'),
      isTrue,
    );
    expect(
      configUsesPlist('97C147071CF9000F007C117D', 'Runner/Info.plist'),
      isTrue,
    );
  });

  test(
    'Dart ve Android debug cleartext sözleşmesi yalnız yerel hostlardır',
    () {
      final validator = read('lib/core/network/api_base_url_validator.dart');
      final debugNetworkConfig = read(
        'android/app/src/debug/res/xml/network_security_config.xml',
      );
      final releaseNetworkConfig = read(
        'android/app/src/main/res/xml/network_security_config.xml',
      );
      final runbook = read('README.md');

      for (final host in ['localhost', '127.0.0.1', '10.0.2.2']) {
        expect(validator, contains("'$host'"));
        expect(debugNetworkConfig, contains('>$host</domain>'));
        expect(runbook, contains('`$host`'));
      }

      expect(validator, isNot(contains('ngrok-free.app')));
      expect(validator, isNot(contains('trycloudflare.com')));
      expect(
        debugNetworkConfig,
        isNot(contains('<domain includeSubdomains="false">ngrok')),
      );
      expect(
        debugNetworkConfig,
        isNot(contains('<domain includeSubdomains="false">cloudflare')),
      );
      expect(
        releaseNetworkConfig,
        contains('cleartextTrafficPermitted="false"'),
      );
    },
  );
}
