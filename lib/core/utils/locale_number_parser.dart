import 'package:intl/intl.dart';

/// Kullanıcı girdisinden sayı ayrıştırma yardımcısı.
///
/// Eski `num.tryParse(text.replaceAll(',', '.'))` deyimi Türkçe bağlamda
/// yanlış çalışır:
///   - `"1.000,50"` → `replaceAll` → `"1.000.50"` → `tryParse` `null` döner.
///   - `"1500,75"` → `"1500.75"` → `1500.75` (yanlışlıkla çalışır).
///
/// Bu helper:
///   - Türkçe locale'de binlik `.` ve ondalık `,` formatını doğru çözer.
///   - Kullanıcı `"1500.75"` veya `"1500,75"` yazsa da kabul eder.
///   - Geçersiz girdide `null` döner (caller snackbar gösterebilir).
class LocaleNumberParser {
  const LocaleNumberParser._();

  /// Türkçe locale'de [text]'i sayıya çevirir. Başarısızsa `null` döner.
  ///
  /// Sıralı denemeler:
  ///   1) `tr_TR` parser — "1.000,50" desteklenir.
  ///   2) Hem virgül hem nokta hem boşluk içermeyen ham sayı → `num.tryParse`.
  ///   3) Tek bir ondalık ayraç olarak `,` veya `.` varsa nokta'ya normalize.
  static num? tryParseTr(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    // 1) Türkçe locale parser ile doğrudan dene.
    try {
      return NumberFormat.decimalPattern('tr_TR').parse(trimmed);
    } on FormatException {
      // Sonraki katmanlara düş.
    }

    // 2) Sadece rakam + opsiyonel `-` + tek bir ondalık ayraç (nokta) ise
    //    doğrudan dart parse.
    final naive = num.tryParse(trimmed);
    if (naive != null) return naive;

    // 3) Tek bir virgül ondalık olarak girilmiş olabilir (binlik yok).
    //    `1500,75` → `1500.75`.
    final commaCount = ','.allMatches(trimmed).length;
    final dotCount = '.'.allMatches(trimmed).length;
    if (commaCount == 1 && dotCount == 0) {
      return num.tryParse(trimmed.replaceFirst(',', '.'));
    }

    return null;
  }
}
