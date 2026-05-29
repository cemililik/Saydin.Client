import 'package:intl/intl.dart';

/// Locale-aware yüzde formatlama.
///
/// `toStringAsFixed(2).replaceAll('.', ',')` deseni Türkçe locale için
/// işliyor görünüyor ama:
///   - Binlik ayracı eklemiyor (12345.67 → "12345,67" beklenen "12.345,67").
///   - EN locale'inde ters etki (12.34 → "12,34" beklenen "12.34").
///   - 1234567% gibi büyük değerler okunamaz.
///
/// `PercentageFormatter.signed(value, locale)` lokal'a göre doğru ayracı
/// + işaret (+/-) seçer.
class PercentageFormatter {
  const PercentageFormatter._();

  /// İşaretli yüzde (`+%12,34` / `-%5,67` TR; `+12.34%` / `-5.67%` EN).
  /// `value` yüzde değeri (örn. 12.34 → "12,34%" / "12.34%").
  static String signed(double value, {String locale = 'tr_TR'}) {
    final sign = value >= 0 ? '+' : '';
    final fmt = NumberFormat.decimalPercentPattern(
      locale: locale,
      decimalDigits: 2,
    );
    // `decimalPercentPattern` 0-1 arası bekler — value/100 ile ölçekle.
    return '$sign${fmt.format(value / 100)}';
  }

  /// İşaretsiz yüzde (genelde başlık veya pasta dilim etiketinde).
  static String unsigned(double value, {String locale = 'tr_TR'}) {
    final fmt = NumberFormat.decimalPercentPattern(
      locale: locale,
      decimalDigits: 2,
    );
    return fmt.format(value / 100);
  }
}
