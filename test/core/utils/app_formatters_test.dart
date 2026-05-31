import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/app_formatters.dart';

/// Simge konumu (önce/sonra) ve % konumu locale'e/intl sürümüne göre değişebildiği
/// için tam string yerine ayraç davranışı `contains` ile doğrulanır; ayraç-yönü
/// (TR virgül-ondalık / EN nokta-ondalık) regresyon kritiktir.
void main() {
  group('AppFormat.tryCurrency', () {
    test('tryCurrency_trLocale_includesThousandDotAndCommaDecimalAndLira', () {
      final s = AppFormat.tryCurrency('tr_TR').format(1234.56);
      expect(s, contains('1.234,56'));
      expect(s, contains('₺'));
    });

    test('tryCurrency_enLocale_includesThousandCommaAndDotDecimalAndLira', () {
      final s = AppFormat.tryCurrency('en_US').format(1234.56);
      expect(s, contains('1,234.56'));
      expect(s, contains('₺'));
    });

    test('tryCurrency_trLocale_decimalDigits0_noFractionalSeparator', () {
      final s = AppFormat.tryCurrency('tr_TR', decimalDigits: 0).format(1234);
      expect(s, contains('1.234'));
      expect(s, isNot(contains(',')));
    });
  });

  group('AppFormat.percent', () {
    test('percent_trLocale_usesCommaDecimal', () {
      expect(AppFormat.percent('tr_TR').format(0.1234), contains('12,34'));
    });

    test('percent_enLocale_usesDotDecimal', () {
      expect(AppFormat.percent('en_US').format(0.1234), contains('12.34'));
    });
  });

  group('AppFormat.decimal', () {
    test('decimal_trLocale_formatsWithDotThousandAndCommaDecimal', () {
      expect(AppFormat.decimal('tr_TR').format(1234.5), '1.234,5');
    });

    test('decimal_enLocale_formatsWithCommaThousandAndDotDecimal', () {
      expect(AppFormat.decimal('en_US').format(1234.5), '1,234.5');
    });
  });
}
