import 'package:decimal/decimal.dart';
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
  /// Gruplama konumları katı doğrulanır. Böylece karşı-locale bir metin
  /// (`tr` için `"1234.5"`, `en` için `"1234,5"`) sessizce 10x/100x farklı
  /// bir değere dönüşmek yerine reddedilir.
  static Decimal? tryParse(String? text, String locale) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final format = NumberFormat.decimalPattern(locale);
    final decimalSeparator = RegExp.escape(format.symbols.DECIMAL_SEP);
    final groupingSeparator = RegExp.escape(format.symbols.GROUP_SEP);
    final strictPattern = RegExp(
      '^[+-]?(?:(?:[0-9]{1,3}(?:$groupingSeparator[0-9]{3})+|[0-9]+)'
      '(?:$decimalSeparator[0-9]+)?|$decimalSeparator[0-9]+)'
      r'$',
    );
    if (!strictPattern.hasMatch(trimmed)) return null;

    final canonical = trimmed
        .replaceAll(format.symbols.GROUP_SEP, '')
        .replaceAll(format.symbols.DECIMAL_SEP, '.');
    try {
      return Decimal.parse(canonical);
    } on FormatException {
      return null;
    }
  }

  /// Düzenleme alanına ön-doldurma için [value]'yu aktif [locale]'in ondalık
  /// ayracıyla, binlik gruplama OLMADAN biçimler — gruplama düzenlemeyi
  /// zorlaştırır (F-07-24 / F-10-16). tr → "1234,5", en → "1234.5".
  /// [tryParse] ile AYNI locale verilince round-trip eder.
  static String formatForInput(Decimal value, String locale) {
    final decimalSeparator = NumberFormat.decimalPattern(
      locale,
    ).symbols.DECIMAL_SEP;
    return value.toString().replaceFirst('.', decimalSeparator);
  }

  /// Form metnini [fromLocale]'den [toLocale]'e güvenli biçimde taşır.
  ///
  /// Metin eski locale'de geçerli değilse kullanıcı girişini ezmez; geçerliyse
  /// önce eski locale ile ayrıştırır, sonra yeni locale ile gruplamasız yazar.
  /// Bu dönüşüm dil değişiminde controller'daki eski ayırıcının yeni parser
  /// tarafından farklı bir büyüklük olarak yorumlanmasını önler.
  static String reformatInput(
    String text, {
    required String fromLocale,
    required String toLocale,
  }) {
    final parsed = tryParse(text, fromLocale);
    return parsed == null ? text : formatForInput(parsed, toLocale);
  }
}
