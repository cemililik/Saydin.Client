import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/network/api_base_url_validator.dart';

void main() {
  group('ApiBaseUrlValidator', () {
    test('boş URL StateError fırlatır', () {
      expect(
        () => ApiBaseUrlValidator.validate(''),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('API_BASE_URL dart-define is required'),
          ),
        ),
      );
    });

    test('invalid URL (scheme yok) StateError fırlatır', () {
      expect(
        () => ApiBaseUrlValidator.validate('not-a-url'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not a valid absolute URL'),
          ),
        ),
      );
    });

    test('https URL kabul edilir', () {
      expect(
        () => ApiBaseUrlValidator.validate('https://api.saydin.app'),
        returnsNormally,
      );
      expect(
        () => ApiBaseUrlValidator.validate('https://api-staging.saydin.app/v1'),
        returnsNormally,
      );
    });

    test('debug modda http://localhost kabul edilir', () {
      expect(
        () => ApiBaseUrlValidator.validate('http://localhost:5080'),
        returnsNormally,
      );
    });

    test('debug modda http://10.0.2.2 kabul edilir (Android emulator)', () {
      expect(
        () => ApiBaseUrlValidator.validate('http://10.0.2.2:5080'),
        returnsNormally,
      );
    });

    test('debug modda http://*.ngrok-free.app kabul edilir', () {
      expect(
        () => ApiBaseUrlValidator.validate('http://abc123.ngrok-free.app'),
        returnsNormally,
      );
    });

    test('debug modda allowlist dışı http host StateError fırlatır', () {
      expect(
        () => ApiBaseUrlValidator.validate('http://api.untrusted.example.com'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not on the dev cleartext allowlist'),
          ),
        ),
      );
    });

    test('ftp veya başka şema StateError fırlatır', () {
      expect(
        () => ApiBaseUrlValidator.validate('ftp://example.com'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('scheme must be https or http'),
          ),
        ),
      );
    });
  });
}
