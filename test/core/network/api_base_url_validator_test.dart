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

  // `flutter test` debug modda koşar (kReleaseMode/kProfileMode == false), bu
  // yüzden release/profile cleartext-reddi dalı validate() üzerinden hiç
  // tetiklenemez. validateForMode seam'i bayrakları enjekte ederek bu
  // güvenlik invariant'ını test edilebilir kılar.
  group(
    'ApiBaseUrlValidator.validateForMode — release/profile cleartext reddi',
    () {
      void expectHttpsRequired(
        String url, {
        required bool isRelease,
        required bool isProfile,
      }) {
        expect(
          () => ApiBaseUrlValidator.validateForMode(
            url,
            isRelease: isRelease,
            isProfile: isProfile,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('must use https in non-debug builds'),
            ),
          ),
        );
      }

      test('release modda http://localhost reddedilir', () {
        expectHttpsRequired(
          'http://localhost:5080',
          isRelease: true,
          isProfile: false,
        );
      });

      test('release modda whitelisted ngrok http bile reddedilir', () {
        expectHttpsRequired(
          'http://abc123.ngrok-free.app',
          isRelease: true,
          isProfile: false,
        );
      });

      test('profile modda http://10.0.2.2 reddedilir', () {
        expectHttpsRequired(
          'http://10.0.2.2:5080',
          isRelease: false,
          isProfile: true,
        );
      });

      test('release/profile modda https sorunsuz geçer', () {
        expect(
          () => ApiBaseUrlValidator.validateForMode(
            'https://api.saydin.app',
            isRelease: true,
            isProfile: false,
          ),
          returnsNormally,
        );
        expect(
          () => ApiBaseUrlValidator.validateForMode(
            'https://api.saydin.app',
            isRelease: false,
            isProfile: true,
          ),
          returnsNormally,
        );
      });

      test('debug modda (her iki bayrak false) http://localhost geçer', () {
        expect(
          () => ApiBaseUrlValidator.validateForMode(
            'http://localhost:5080',
            isRelease: false,
            isProfile: false,
          ),
          returnsNormally,
        );
      });
    },
  );
}
