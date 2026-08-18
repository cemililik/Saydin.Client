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

    test('Türkçe binlik ayraçlı tutarları yakalar', () {
      expect(scrubber.redactText('tutar=47.010,34'), 'tutar=<NUMBER>');
      expect(scrubber.redactText('tutar=1.250.500'), 'tutar=<NUMBER>');
      expect(scrubber.redactText('tutar=1.250.500,99'), 'tutar=<NUMBER>');
      // EN format de yakalanır
      expect(scrubber.redactText('amount=1,250,500.99'), 'amount=<NUMBER>');
    });

    test(
      'küçük tutarlar ve teknik görünen sayılar dahil serbest metindeki tüm sayıları sansürler',
      () {
        expect(scrubber.redactText('amount=99'), 'amount=<NUMBER>');
        expect(scrubber.redactText('price=0.5'), 'price=<NUMBER>');
        expect(
          scrubber.redactText('http=404 retry=3'),
          'http=<NUMBER> retry=<NUMBER>',
        );
      },
    );

    test('Asset sembolü pair pattern (USDTRY, BTC/USD) sansürler', () {
      expect(scrubber.redactText('symbol=USD/TRY'), 'symbol=<SYMBOL>');
      expect(scrubber.redactText('pair=BTC-USD'), 'pair=<SYMBOL>');
    });

    test('Composite teknik terim (USER-AGENT, HTTP-GET) korunur', () {
      // `_assetSymbol` regex'i pair'i yakalar ama split sonra
      // tüm parçalar `_safeAllCaps`'te olduğu için orijinal korunur.
      // Önceki davranış: pair'in tamamı kümede olmadığı için sansürlenir
      // (false positive). Şimdi split kontrolü ile düzeltildi.
      expect(scrubber.redactText('header=USER-AGENT'), 'header=USER-AGENT');
      expect(scrubber.redactText('verb=HTTP-GET'), 'verb=HTTP-GET');
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

    test('Allowlist değerlerinin tür ve aralık şeması zorunludur', () {
      final filtered = scrubber.filterAllowedKeys({
        'httpStatus': 503,
        'durationMs': 99,
        'backendOk': true,
        'method': 'POST',
        'endpoint': '/v1/what-if/calculate',
        'feature': 'what_if',
        'os': 'ios',
        'os_version': '18.6',
        'app_version': '1.2.3+4',
      });
      expect(filtered!['httpStatus'], 503);
      expect(filtered['durationMs'], 99);
      expect(filtered['backendOk'], isTrue);
      expect(filtered['endpoint'], '/v1/what-if/calculate');
      expect(filtered['feature'], 'what_if');
    });

    test('Allowlist anahtarı yanlış değer şemasıyla PII bypass edemez', () {
      final filtered = scrubber.filterAllowedKeys({
        'httpStatus': 'amount=99',
        'durationMs': -1,
        'backendOk': 'true',
        'method': 'BUY BTC',
        'endpoint': '/v1/account/42',
        'feature': 'BTC/USD',
      });
      expect(filtered!.values, everyElement('<REDACTED>'));
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
      'endpoint anahtarı için path-only enforcement (query/fragment yutulur)',
      () {
        final filtered = scrubber.filterAllowedKeys({
          'endpoint': '/v1/what-if/calculate?date=2020-01-15&amount=47010#x',
        });
        // Query string ve fragment scrubber içinde tamamen kesilir; sadece
        // path döner. Bu, identifier sızıntısına karşı in-depth savunma.
        expect(filtered!['endpoint'], '/v1/what-if/calculate');
      },
    );

    test('endpoint absolute URL\'de scheme + host atılır', () {
      final filtered = scrubber.filterAllowedKeys({
        'endpoint': 'https://api.saydin.app/v1/account?id=42',
      });
      expect(filtered!['endpoint'], '/v1/account');
    });

    test('endpoint non-string değer için <REDACTED>', () {
      final filtered = scrubber.filterAllowedKeys({'endpoint': 42});
      expect(filtered!['endpoint'], '<REDACTED>');
    });

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

    test('message template ve typed params da sansürlenir', () {
      final hint = Hint();
      final event = SentryEvent(
        message: const SentryMessage(
          'safe',
          template: 'amount=99 asset=BTC/USD',
          params: ['price=0.5', 99],
        ),
      );
      final message = scrubber.scrubEvent(event, hint)!.message!;
      expect(message.template, 'amount=<NUMBER> asset=<SYMBOL>');
      expect(message.params, ['price=<NUMBER>', '<REDACTED>']);
    });

    test(
      'SDK typed contexts deny-by-default drop edilir; yalnız custom telemetri korunur',
      () {
        final hint = Hint();
        final contexts =
            Contexts(
                device: const SentryDevice(
                  name: 'Cemil iPhone',
                  deviceUniqueIdentifier:
                      '550e8400-e29b-41d4-a716-446655440000',
                ),
              )
              ..['app_telemetry'] = <String, Object?>{
                'httpStatus': 503,
                'amount': 99,
              };
        final scrubbed = scrubber.scrubEvent(
          SentryEvent(contexts: contexts),
          hint,
        )!;
        expect(scrubbed.contexts.device, isNull);
        expect(scrubbed.contexts['app_telemetry'], {
          'httpStatus': 503,
          'amount': '<REDACTED>',
        });
      },
    );

    test('Attachments + Hint.screenshot/viewHierarchy zorla kaldırılır', () {
      final hint = Hint();
      hint.attachments.add(SentryAttachment.fromIntList([1, 2, 3], 'shot.png'));
      hint.screenshot = SentryAttachment.fromIntList([9], 's.png');
      hint.viewHierarchy = SentryAttachment.fromIntList([9], 'vh.json');
      final event = SentryEvent();
      scrubber.scrubEvent(event, hint);
      expect(hint.attachments, isEmpty);
      expect(hint.screenshot, isNull);
      expect(hint.viewHierarchy, isNull);
    });

    test('SentryException.value PII\'den temizlenir', () {
      final hint = Hint();
      final event = SentryEvent(
        exceptions: const [
          SentryException(
            type: 'FormatException',
            value: 'Invalid date 2020-01-15 amount=47010,34',
          ),
        ],
      );
      final scrubbed = scrubber.scrubEvent(event, hint);
      final ex = scrubbed!.exceptions!.first;
      expect(ex.type, 'FormatException');
      expect(ex.value, contains('<DATE>'));
      expect(ex.value, contains('<NUMBER>'));
      expect(ex.value, isNot(contains('2020-01-15')));
      expect(ex.value, isNot(contains('47010,34')));
    });

    test('SentryUser PII alanları sansürlenir (privacy by default)', () {
      final hint = Hint();
      final event = SentryEvent(
        user: SentryUser(
          id: 'user-123',
          email: 'a@b.com',
          username: 'alice',
          ipAddress: '1.2.3.4',
        ),
      );
      final scrubbed = scrubber.scrubEvent(event, hint);
      final user = scrubbed!.user!;
      // SentryUser boş constructor reddedildiği için anonim placeholder bırakılır.
      expect(user.id, '<REDACTED>');
      expect(user.email, isNull);
      expect(user.username, isNull);
      expect(user.ipAddress, isNull);
    });

    test('fingerprint elemanları redactText\'ten geçer', () {
      final hint = Hint();
      final event = SentryEvent(
        fingerprint: const ['error-BTC/USD-2020-01-15'],
      );
      final scrubbed = scrubber.scrubEvent(event, hint);
      expect(scrubbed!.fingerprint!.first, contains('<SYMBOL>'));
      expect(scrubbed.fingerprint!.first, contains('<DATE>'));
    });

    test('transaction adı redact edilir', () {
      final hint = Hint();
      final event = SentryEvent(transaction: 'GET /v1/quotes/BTC/USD');
      final scrubbed = scrubber.scrubEvent(event, hint);
      expect(scrubbed!.transaction, contains('<SYMBOL>'));
    });

    test(
      'SentryRequest constructor ile query/body/cookie GERÇEKTEN temizlenir',
      () {
        // SDK `copyWith(queryString: null)` "değiştirme" anlamına gelir → bypass.
        // `_scrubRequest` constructor kullanmalı.
        final hint = Hint();
        final event = SentryEvent(
          request: SentryRequest(
            url: 'https://api.example.com/v1/what-if/calculate',
            method: 'POST',
            queryString: 'date=2020-01-15&amount=47010',
            cookies: 'session=secret',
            data: const {'asset': 'BTC', 'amount': 47010},
            headers: const {
              'Authorization': 'Bearer secret-token',
              'Content-Type': 'application/json',
              'User-Agent': 'Cemil iPhone',
            },
          ),
        );
        final scrubbed = scrubber.scrubEvent(event, hint);
        final req = scrubbed!.request!;
        expect(req.queryString, isNull);
        expect(req.cookies, isNull);
        expect(req.data, isNull);
        expect(req.apiTarget, isNull);
        expect(req.headers, isNot(contains('Authorization')));
        expect(req.headers, isNot(contains('User-Agent')));
        expect(req.headers, contains('Content-Type'));
      },
    );

    test('URL içindeki dinamik path identifier redact edilir', () {
      final event = SentryEvent(
        request: SentryRequest(
          url: 'https://api.example.com/v1/account/42?amount=99',
        ),
      );
      final request = scrubber.scrubEvent(event, Hint())!.request!;
      expect(request.url, '<REDACTED>');
    });
  });
}
