import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/turkish_text.dart';

void main() {
  group('toUpperCaseTr', () {
    test('"sil" → "SİL" (dotted I)', () {
      expect(toUpperCaseTr('sil'), 'SİL');
    });

    test('"tercihler" → "TERCİHLER" (dotted I)', () {
      expect(toUpperCaseTr('tercihler'), 'TERCİHLER');
    });

    test('"ışık" → "IŞIK" (dotless I)', () {
      expect(toUpperCaseTr('ışık'), 'IŞIK');
    });

    test('Dart default upper case karşılaştırması', () {
      // Bug yüzeyini doğrula: Dart toUpperCase yanlış sonuç verir.
      expect('sil'.toUpperCase(), 'SIL');
      expect('sil'.toUpperCase() == 'SİL', isFalse);
      // Türkçe-aware helper doğru sonucu üretir.
      expect(toUpperCaseTr('sil'), isNot('SIL'));
      expect(toUpperCaseTr('sil'), 'SİL');
    });

    test('Diğer karakterleri etkilemez', () {
      expect(toUpperCaseTr('hello'), 'HELLO');
      expect(toUpperCaseTr('ABC123'), 'ABC123');
    });
  });

  group('toLowerCaseTr', () {
    test('"SİL" → "sil" (dotted i)', () {
      expect(toLowerCaseTr('SİL'), 'sil');
    });

    test('"IŞIK" → "ışık" (dotless ı)', () {
      expect(toLowerCaseTr('IŞIK'), 'ışık');
    });
  });

  group('eqIgnoreCaseTr', () {
    test('Türkçe karakter case farklı olsa eşit', () {
      expect(eqIgnoreCaseTr('sil', 'SİL'), isTrue);
      expect(eqIgnoreCaseTr('SİL', 'sil'), isTrue);
      expect(eqIgnoreCaseTr('Sil', 'SİL'), isTrue);
      expect(eqIgnoreCaseTr('DELETE', 'delete'), isTrue);
    });

    test('Trim uygulanır', () {
      expect(eqIgnoreCaseTr('  sil  ', 'SİL'), isTrue);
    });

    test('Farklı kelime → false', () {
      expect(eqIgnoreCaseTr('sil', 'ekle'), isFalse);
    });
  });
}
