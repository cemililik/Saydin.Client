import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/network/certificate_pinning.dart';

void main() {
  group('CertificatePinning.parsePinsForTest', () {
    test('boş string boş set döner', () {
      expect(CertificatePinning.parsePinsForTest(''), isEmpty);
      expect(CertificatePinning.parsePinsForTest('   '), isEmpty);
    });

    test('tek hash parse edilir, lowercase normalize edilir', () {
      final pins = CertificatePinning.parsePinsForTest('AABBCCDD');
      expect(pins, {'aabbccdd'});
    });

    test('virgülle ayrılmış liste parse edilir', () {
      final pins = CertificatePinning.parsePinsForTest('aa,bb,cc');
      expect(pins, {'aa', 'bb', 'cc'});
    });

    test('sha256/ prefix soyulur', () {
      final pins = CertificatePinning.parsePinsForTest(
        'sha256/aabb,sha256:ccdd,eeff',
      );
      expect(pins, {'aabb', 'ccdd', 'eeff'});
    });

    test('whitespace ve duplicate temizlenir', () {
      final pins = CertificatePinning.parsePinsForTest('  aa  , aa, BB,, cc ');
      expect(pins, {'aa', 'bb', 'cc'});
    });
  });

  test('isEnabled default false (pin dart-define yok)', () {
    // CI test ortamında PINNED_CERT_SHA256 dart-define geçilmediği için
    // pinning kapalı olmalı; bu, dev/test cycle'ı bozulmadığını doğrular.
    expect(CertificatePinning.isEnabled, isFalse);
  });
}
