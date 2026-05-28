import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:saydin/core/utils/percentage_formatter.dart';

void main() {
  setUpAll(() async {
    // intl locale data initialize (NumberFormat tr_TR için gerekli).
    await initializeDateFormatting();
  });

  group('PercentageFormatter.signed', () {
    test('pozitif değer + işareti alır, TR ayracı (virgül)', () {
      expect(PercentageFormatter.signed(12.34), '+%12,34');
    });

    test('negatif değer - işareti zaten içeriyor (manuel + yok)', () {
      expect(PercentageFormatter.signed(-5.67), '-%5,67');
    });

    test('0 değer + işareti alır', () {
      expect(PercentageFormatter.signed(0), '+%0,00');
    });

    test('binlik ayracı eklenir (en sık görmezden gelinen sorun)', () {
      // toStringAsFixed(2).replaceAll('.', ',') burada binlik koymazdı.
      expect(PercentageFormatter.signed(12345.67), '+%12.345,67');
    });

    test('EN locale verilirse nokta ondalık ayraç', () {
      expect(PercentageFormatter.signed(12.34, locale: 'en_US'), '+12.34%');
    });

    test('Çok küçük yüzde 2 ondalık koruyor', () {
      expect(PercentageFormatter.signed(0.05), '+%0,05');
    });
  });

  group('PercentageFormatter.unsigned', () {
    test('işaret eklenmiyor', () {
      expect(PercentageFormatter.unsigned(12.34), '%12,34');
      expect(PercentageFormatter.unsigned(-5.67), '-%5,67');
    });
  });
}
