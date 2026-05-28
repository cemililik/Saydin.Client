import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Para tutarı parse + format yardımcıları.
///
/// **Neden Decimal?** CLAUDE.md "Yasak Listesi": "para için double/float
/// YASAK". `double` IEEE-754 binary olduğu için ondalık tutarları
/// (0.1 + 0.2 = 0.30000000000000004) yanlış toplar. Finansal hesaplama
/// sonuçlarında kullanıcı 1 kuruşluk fark görür → güven kaybı.
///
/// **Strateji:**
/// 1. Backend JSON'ından gelen değer `num` veya `String` olabilir; ikisi
///    de güvenle `Decimal`'a çevrilir.
/// 2. Domain entity'leri ve hesaplama logic'i `Decimal` üzerinden çalışır.
/// 3. UI'da `NumberFormat.currency` `double` ister — `.toDouble()` çağrısı
///    SADECE gösterim katmanında yapılır (precision loss tolere edilir,
///    çünkü görsel format zaten ondalık hane sınırlıdır).
class MoneyParser {
  const MoneyParser._();

  /// JSON'dan zorunlu para alanı parse'ı.
  ///
  /// Backend kontratı `num` (int/double) veya `String` ("47010.34")
  /// gönderebilir — ikisini de kabul eder. Boş string, null veya
  /// parse edilemeyen değer için `FormatException`.
  static Decimal requireDecimal(Object? value, String field) {
    final parsed = tryDecimal(value);
    if (parsed == null) {
      throw FormatException('JSON parse: $field para alanı geçersiz ($value)');
    }
    return parsed;
  }

  /// JSON'dan opsiyonel para alanı parse'ı. `null` veya parse edilemeyen
  /// değer için `null` döner — caller default veya conditional kullanır.
  static Decimal? tryDecimal(Object? value) {
    if (value == null) return null;
    if (value is Decimal) return value;
    if (value is int) return Decimal.fromInt(value);
    if (value is double) {
      // Decimal.parse(double.toString()) güvenli — Dart double toString()
      // round-trip safe ondalık rep döner ("0.1" → "0.1").
      if (value.isNaN || value.isInfinite) return null;
      return Decimal.parse(value.toString());
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        return Decimal.parse(trimmed);
      } on FormatException {
        return null;
      }
    }
    return null;
  }

  /// JSON'a serialize: Decimal → String. Backend `num` veya `String`
  /// kabul ediyorsa String tercih edilir — precision korunur.
  static String toJsonString(Decimal value) => value.toString();
}

/// `Decimal` ↔ UI format köprüsü.
///
/// `NumberFormat.currency` ve `NumberFormat.compactCurrency` API'leri
/// `double` ister; Decimal kullanım'ında her widget'ta `.toDouble()` tek
/// noktada yapılmalı. Bu extension boilerplate'i azaltır.
extension MoneyDecimalFormat on Decimal {
  /// Display'e geçmeden double'a çevir. Precision loss sadece görsel
  /// formatı etkiler (NumberFormat zaten 2 ondalık haneye yuvarlar).
  double toDisplayDouble() => toDouble();
}

/// `NumberFormat.currency(locale: 'tr_TR', symbol: '₺')` kısa yolu.
NumberFormat tryCurrencyFormatter({String locale = 'tr_TR'}) =>
    NumberFormat.currency(locale: locale, symbol: '₺');
