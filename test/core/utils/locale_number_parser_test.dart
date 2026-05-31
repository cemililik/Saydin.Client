import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/locale_number_parser.dart';

void main() {
  group('LocaleNumberParser.tryParse (locale-duyarlı)', () {
    test('EN: noktalı ondalık', () {
      expect(LocaleNumberParser.tryParse('1234.5', 'en_US'), 1234.5);
    });

    test('EN: virgül binlik + nokta ondalık', () {
      expect(LocaleNumberParser.tryParse('1,000.50', 'en_US'), 1000.5);
    });

    test('TR: virgüllü ondalık', () {
      expect(LocaleNumberParser.tryParse('1234,5', 'tr_TR'), 1234.5);
    });

    test('TR: nokta binlik + virgül ondalık', () {
      expect(LocaleNumberParser.tryParse('1.000,50', 'tr_TR'), 1000.5);
    });

    test('null / boş / geçersiz → null', () {
      expect(LocaleNumberParser.tryParse(null, 'tr_TR'), isNull);
      expect(LocaleNumberParser.tryParse('', 'tr_TR'), isNull);
      expect(LocaleNumberParser.tryParse('   ', 'tr_TR'), isNull);
      expect(LocaleNumberParser.tryParse('abc', 'en_US'), isNull);
    });

    test('round-trip EN: formatForInput → tryParse aynı değer', () {
      final s = LocaleNumberParser.formatForInput(1234.56, 'en_US');
      expect(s, '1234.56');
      expect(LocaleNumberParser.tryParse(s, 'en_US'), 1234.56);
    });

    test('round-trip TR: formatForInput → tryParse aynı değer', () {
      final s = LocaleNumberParser.formatForInput(1234.56, 'tr_TR');
      expect(s, '1234,56');
      expect(LocaleNumberParser.tryParse(s, 'tr_TR'), 1234.56);
    });

    test(
      'REGRESYON (C-1): EN-format ön-doldurma aynı locale ile parse edilince ŞİŞMEZ',
      () {
        // Eski hata: formatForInput(_, "en")="1234.5" sonra tryParseTr (TR parser)
        // "." karakterini binlik sayıp 12345.0 döndürüyordu (10x). Locale-duyarlı
        // tryParse ile aynı locale verilince doğru değer döner.
        final prefill = LocaleNumberParser.formatForInput(1234.5, 'en_US');
        expect(prefill, '1234.5');
        expect(LocaleNumberParser.tryParse(prefill, 'en_US'), 1234.5);
        expect(LocaleNumberParser.tryParse('500.50', 'en_US'), 500.5);
      },
    );
  });
}
