import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/app_formatters.dart';

/// Simge konumu (önce/sonra) ve % konumu locale'e/intl sürümüne göre değişebildiği
/// için tam string yerine ayraç davranışı `contains` ile doğrulanır; ayraç-yönü
/// (TR virgül-ondalık / EN nokta-ondalık) regresyon kritiktir.
void main() {
  group('AppFormat.tryCurrency', () {
    test('TR: binlik nokta + ondalık virgül + ₺', () {
      final s = AppFormat.tryCurrency('tr_TR').format(1234.56);
      expect(s, contains('1.234,56'));
      expect(s, contains('₺'));
    });

    test('EN: binlik virgül + ondalık nokta + ₺', () {
      final s = AppFormat.tryCurrency('en_US').format(1234.56);
      expect(s, contains('1,234.56'));
      expect(s, contains('₺'));
    });

    test('decimalDigits override (0)', () {
      final s = AppFormat.tryCurrency('tr_TR', decimalDigits: 0).format(1234);
      expect(s, contains('1.234'));
      expect(s, isNot(contains(',')));
    });
  });

  group('AppFormat.percent', () {
    test('TR: ondalık virgül', () {
      expect(AppFormat.percent('tr_TR').format(0.1234), contains('12,34'));
    });

    test('EN: ondalık nokta', () {
      expect(AppFormat.percent('en_US').format(0.1234), contains('12.34'));
    });
  });

  group('AppFormat.decimal', () {
    test('TR: 1.234,5', () {
      expect(AppFormat.decimal('tr_TR').format(1234.5), '1.234,5');
    });

    test('EN: 1,234.5', () {
      expect(AppFormat.decimal('en_US').format(1234.5), '1,234.5');
    });
  });
}
