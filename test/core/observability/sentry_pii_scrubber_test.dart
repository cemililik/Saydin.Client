import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/observability/sentry_pii_scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  const scrubber = SentryPiiScrubber();

  group('SentryPiiScrubber.redactText', () {
    test('ISO 8601 tarihleri sansürler', () {
      expect(scrubber.redactText('buy=2020-01-15'), 'buy=<DATE>');
      expect(scrubber.redactText('ts=2020-01-15T12:34:56.789Z'), 'ts=<DATE>');
    });

    test('4+ haneli sayıları sansürler (tutar/fiyat)', () {
      expect(scrubber.redactText('amount=47010.34'), 'amount=<NUMBER>');
      expect(scrubber.redactText('price=120000,50'), 'price=<NUMBER>');
    });

    test('3 haneli sayıları korur (HTTP status vb.)', () {
      expect(scrubber.redactText('http=404'), 'http=404');
      expect(scrubber.redactText('retry=3 status=503'), 'retry=3 status=503');
    });

    test('Asset sembolü pair pattern (USDTRY, BTC/USD) sansürler', () {
      expect(scrubber.redactText('symbol=USD/TRY'), 'symbol=<SYMBOL>');
      expect(scrubber.redactText('pair=BTC-USD'), 'pair=<SYMBOL>');
    });

    test('Güvenli ALL_CAPS sözcükleri korur', () {
      expect(
        scrubber.redactText('HTTP GET API JSON OK BLOC'),
        'HTTP GET API JSON OK BLOC',
      );
      expect(scrubber.redactText('method=POST'), 'method=POST');
    });

    test('UUID sansürler', () {
      const id = '550e8400-e29b-41d4-a716-446655440000';
      expect(scrubber.redactText('deviceId=$id'), 'deviceId=<UUID>');
    });

    test('E-posta adresi sansürler', () {
      expect(
        scrubber.redactText('contact=user@example.com'),
        'contact=<EMAIL>',
      );
    });

    test('Karışık PII içeren mesajı tamamen sansürler', () {
      const input = 'WhatIf calculated: BTC/USD 2020-01-15 amount=10000';
      final result = scrubber.redactText(input);
      // Symbol pair, date, number redacted; "calculated" güvenli kelime;
      // "amount" ve "WhatIf" ALL_CAPS değil.
      expect(result, contains('<SYMBOL>'));
      expect(result, contains('<DATE>'));
      expect(result, contains('<NUMBER>'));
      expect(result, isNot(contains('BTC/USD')));
      expect(result, isNot(contains('2020-01-15')));
      expect(result, isNot(contains('10000')));
    });
  });

  group('SentryPiiScrubber.filterAllowedKeys', () {
    test('Allowlist anahtarlarını korur', () {
      final filtered = scrubber.filterAllowedKeys({
        'errorType': 'NoInternetError',
        'httpStatus': 503,
        'feature': 'what_if',
      });
      expect(filtered, {
        'errorType': 'NoInternetError',
        'httpStatus': 503,
        'feature': 'what_if',
      });
    });

    test('Allowlist dışı anahtarları <REDACTED> ile değiştirir', () {
      final filtered = scrubber.filterAllowedKeys({
        'amount': 10000,
        'assetSymbol': 'BTC',
        'buyDate': '2020-01-15',
      });
      expect(filtered, {
        'amount': '<REDACTED>',
        'assetSymbol': '<REDACTED>',
        'buyDate': '<REDACTED>',
      });
    });

    test(
      'Allowlist anahtar değerlerinde PII pattern\'ları da scrub edilir',
      () {
        final filtered = scrubber.filterAllowedKeys({
          'endpoint': '/v1/what-if/calculate?date=2020-01-15&amount=47010',
        });
        // Query string scrubber tarafından korunmuyor; URL içindeki tarih ve
        // sayı pattern'leri sansürlenir.
        expect(filtered!['endpoint'], contains('<DATE>'));
        expect(filtered['endpoint'], contains('<NUMBER>'));
      },
    );

    test('null map için null döner', () {
      expect(scrubber.filterAllowedKeys(null), isNull);
    });

    test('İç içe map\'ler için recursive scrub', () {
      final filtered = scrubber.filterAllowedKeys({
        'feature': 'portfolio',
        'data': {'amount': 5000, 'symbol': 'USD/TRY'},
      });
      // `data` allowlist'te değil → REDACTED. İç recursion test'i için ayrı
      // path: `feature` allowlist'te, içinde nested olmadığı için string kalır.
      expect(filtered!['feature'], 'portfolio');
      expect(filtered['data'], '<REDACTED>');
    });
  });

  group('SentryPiiScrubber.scrubBreadcrumb', () {
    test(
      'Allowlist prefix\'li mesajı korur ama içerikteki PII redact eder',
      () {
        final hint = Hint();
        final crumb = Breadcrumb(
          message: 'what_if.calculated: BTC/USD 2020-01-15',
          category: 'what_if',
          data: const {'feature': 'what_if', 'amount': 10000},
        );
        final scrubbed = scrubber.scrubBreadcrumb(crumb, hint);
        expect(scrubbed, isNotNull);
        expect(scrubbed!.message, startsWith('what_if.calculated'));
        expect(scrubbed.message, contains('<SYMBOL>'));
        expect(scrubbed.message, contains('<DATE>'));
        expect(scrubbed.data, {'feature': 'what_if', 'amount': '<REDACTED>'});
      },
    );

    test('Allowlist olmayan mesajı <REDACTED> ile değiştirir', () {
      final hint = Hint();
      final crumb = Breadcrumb(
        message: 'random user input here',
        category: 'unknown',
      );
      final scrubbed = scrubber.scrubBreadcrumb(crumb, hint);
      expect(scrubbed!.message, '<REDACTED>');
    });

    test('null mesaj korunur', () {
      final hint = Hint();
      final crumb = Breadcrumb(category: 'app');
      final scrubbed = scrubber.scrubBreadcrumb(crumb, hint);
      expect(scrubbed!.message, isNull);
    });
  });

  group('SentryPiiScrubber.scrubEvent', () {
    test('Event message\'ını PII\'den temizler', () {
      final hint = Hint();
      final event = SentryEvent(
        message: const SentryMessage(
          'Failed for BTC/USD on 2020-01-15 amount=10000',
        ),
      );
      final scrubbed = scrubber.scrubEvent(event, hint);
      expect(scrubbed!.message!.formatted, contains('<SYMBOL>'));
      expect(scrubbed.message!.formatted, contains('<DATE>'));
      expect(scrubbed.message!.formatted, contains('<NUMBER>'));
    });

    test('Attachments (screenshot) zorla kaldırılır', () {
      final hint = Hint();
      hint.attachments.add(SentryAttachment.fromIntList([1, 2, 3], 'shot.png'));
      final event = SentryEvent();
      scrubber.scrubEvent(event, hint);
      expect(hint.attachments, isEmpty);
    });
  });
}
