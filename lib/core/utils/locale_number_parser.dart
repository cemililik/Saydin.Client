import 'package:intl/intl.dart';

/// Kullanıcı girdisinden **locale-duyarlı** sayı ayrıştırma/biçimleme yardımcısı.
///
/// Tutar alanları locale-duyarlıdır: EN kullanıcı `1,234.56`, TR kullanıcı
/// `1.234,56` görür ve yazar. Bu nedenle hem ön-doldurma ([formatForInput]) hem
/// ayrıştırma ([tryParse]) AYNI locale ile yapılmalıdır; aksi halde ayraçlar
/// ters yorumlanır ve tutar 10x/100x şişer veya küçülür (locale asimetrisi).
class LocaleNumberParser {
  const LocaleNumberParser._();

  /// [text]'i [locale]'in ondalık/binlik ayraçlarına göre sayıya çevirir;
  /// başarısızsa `null` döner (caller snackbar gösterebilir).
  ///
  /// [formatForInput] ile AYNI locale verildiğinde tam round-trip sağlar:
  ///   - tr: `"1.000,50"` → `1000.5`, `"1234,5"` → `1234.5`
  ///   - en: `"1,000.50"` → `1000.5`, `"1234.5"` → `1234.5`
  ///
  /// Locale-strict parse `FormatException` atarsa, ayraçsız ham makine sayısına
  /// (`"1234.5"`) düşülür.
  static num? tryParse(String? text, String locale) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    try {
      return NumberFormat.decimalPattern(locale).parse(trimmed);
    } on FormatException {
      // Locale ayraçlarına uymayan ham sayı (ör. "1234.5") için son çare.
      return num.tryParse(trimmed);
    }
  }

  /// Düzenleme alanına ön-doldurma için [value]'yu aktif [locale]'in ondalık
  /// ayracıyla, binlik gruplama OLMADAN biçimler — gruplama düzenlemeyi
  /// zorlaştırır (F-07-24 / F-10-16). tr → "1234,5", en → "1234.5".
  /// [tryParse] ile AYNI locale verilince round-trip eder.
  static String formatForInput(num value, String locale) {
    final fmt = NumberFormat.decimalPattern(locale)
      ..turnOffGrouping()
      ..maximumFractionDigits = 8;
    return fmt.format(value);
  }
}
