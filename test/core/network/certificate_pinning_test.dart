import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/network/certificate_pinning.dart';

// Geçerli 64-char hex SHA-256 örnekleri (sadece test için).
const _validHex1 =
    'aabbccddeeff00112233445566778899aabbccddeeff00112233445566778899';
const _validHex2 =
    '0011223344556677889900112233445566778899001122334455667788990011';

void main() {
  group('CertificatePinning.parsePinsForTest', () {
    test('boş string boş set döner', () {
      expect(CertificatePinning.parsePinsForTest(''), isEmpty);
      expect(CertificatePinning.parsePinsForTest('   '), isEmpty);
    });

    test('64-char hex hash parse edilir, lowercase normalize edilir', () {
      final pins = CertificatePinning.parsePinsForTest(
        _validHex1.toUpperCase(),
      );
      expect(pins, {_validHex1});
    });

    test('virgülle ayrılmış liste parse edilir', () {
      final pins = CertificatePinning.parsePinsForTest(
        '$_validHex1,$_validHex2',
      );
      expect(pins, {_validHex1, _validHex2});
    });

    test('sha256/ ve sha256: prefix soyulur', () {
      final pins = CertificatePinning.parsePinsForTest(
        'sha256/$_validHex1,sha256:$_validHex2',
      );
      expect(pins, {_validHex1, _validHex2});
    });

    test('whitespace ve duplicate temizlenir', () {
      final pins = CertificatePinning.parsePinsForTest(
        '  $_validHex1  , $_validHex1, $_validHex2,,',
      );
      expect(pins, {_validHex1, _validHex2});
    });

    test('hex olmayan pin StateError fırlatır (fail-loud)', () {
      // Eski test'te "aabbccdd" gibi kısa string'ler geçiyordu — artık
      // 64-char hex zorunluluğu var; sessiz drop yerine StateError.
      expect(
        () => CertificatePinning.parsePinsForTest('aabbccdd'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => CertificatePinning.parsePinsForTest('not-hex-at-all'),
        throwsA(isA<StateError>()),
      );
      // Base64 (Apple/Google native pinning genelde base64 kullanır);
      // bizim formatımız hex — explicit reject.
      expect(
        () => CertificatePinning.parsePinsForTest('sha256/AbCdEf1234567890+/='),
        throwsA(isA<StateError>()),
      );
    });

    test('63 veya 65 karakter hex StateError fırlatır', () {
      expect(
        () => CertificatePinning.parsePinsForTest(_validHex1.substring(1)),
        throwsA(isA<StateError>()),
      );
      expect(
        () => CertificatePinning.parsePinsForTest('${_validHex1}f'),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('isEnabled default false (pin dart-define yok)', () {
    // CI test ortamında PINNED_CERT_SHA256 dart-define geçilmediği için
    // pinning kapalı olmalı; bu, dev/test cycle'ı bozulmadığını doğrular.
    expect(CertificatePinning.isEnabled, isFalse);
  });

  // validateCertificate callback'inin saf çekirdeği. Gerçek bir TLS
  // handshake unit test'te kurulamadığı için fingerprint karşılaştırma
  // mantığı matchesPin seam'i üzerinden doğrulanır.
  group('CertificatePinning.matchesPin', () {
    final der = <int>[0x01, 0x02, 0x03, 0x04, 0x05];
    final fingerprint = sha256.convert(der).toString().toLowerCase();

    test('null cert (der) → false (pin yoksa istek reddedilir)', () {
      expect(CertificatePinning.matchesPin(null, {fingerprint}), isFalse);
    });

    test('eşleşen fingerprint → true', () {
      expect(CertificatePinning.matchesPin(der, {fingerprint}), isTrue);
    });

    test('eşleşmeyen fingerprint → false', () {
      expect(
        CertificatePinning.matchesPin(der, {_validHex1, _validHex2}),
        isFalse,
      );
    });

    test('boş pin set → false', () {
      expect(CertificatePinning.matchesPin(der, const <String>{}), isFalse);
    });

    test('çoklu pin (primary + backup) içinde eşleşme → true', () {
      expect(
        CertificatePinning.matchesPin(der, {_validHex1, fingerprint}),
        isTrue,
      );
    });
  });
}
