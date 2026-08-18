import 'package:intl/intl.dart';

/// Aktif locale'e göre yapılandırılmış `intl` formatter fabrikası (F-06-01).
///
/// **Neden merkezî fabrika?** Önceden her widget `NumberFormat.currency(
/// locale: 'tr_TR', ...)` ve `DateFormat('dd.MM.yyyy', 'tr_TR')` gibi sabit
/// `'tr_TR'` literal'leriyle `static` formatter tanımlıyordu. Bu, kullanıcı
/// İngilizce'ye geçtiğinde para/yüzde değerlerinin yine Türkçe ayraçla
/// ("₺1.234,56", "+%12,34") gösterilmesine yol açıyordu (static alanlar
/// locale değişiminde yeniden kurulamaz). Burada formatter'lar `context
/// .localeName` ile çağrı anında üretilir; binlik/ondalık ayraçları aktif
/// dile göre seçilir.
///
/// Kullanım:
/// ```dart
/// final locale = context.localeName;
/// final tryFmt = AppFormat.tryCurrency(locale);
/// Text(tryFmt.format(amount));
/// ```
class AppFormat {
  const AppFormat._();

  /// TL para birimi. `₺` simgesi sabittir — tutarlar her zaman TRY cinsinden;
  /// yalnızca ayraç/gruplama locale'e göre değişir (tr "₺1.234,56" /
  /// en "₺1,234.56").
  static NumberFormat tryCurrency(String locale, {int decimalDigits = 2}) =>
      NumberFormat.currency(
        locale: locale,
        symbol: '₺',
        decimalDigits: decimalDigits,
      );

  /// İşaretsiz ondalık (binlik ayraçlı): "1.234,56" (tr) / "1,234.56" (en).
  static NumberFormat decimal(String locale) =>
      NumberFormat.decimalPattern(locale);

  /// Özel pattern'li sayı (ör. miktar gösterimi `'#,##0.####'`).
  static NumberFormat custom(String pattern, String locale) =>
      NumberFormat(pattern, locale);

  /// Kısa tarih — Türk biçimi gün.ay.yıl (CLAUDE.md). Pattern sabit
  /// olduğundan çıktı bu desende locale'den bağımsızdır; locale yine de
  /// geçilir ki çağrı yerlerinde sabit `'tr_TR'` literal'i kalmasın.
  static DateFormat date(String locale) => DateFormat('dd.MM.yyyy', locale);

  /// İşaretsiz yüzde formatter'ı. `format` 0-1 ölçeğinde değer bekler —
  /// yüzde değerini `value / 100` ile geçir.
  static NumberFormat percent(String locale, {int decimalDigits = 2}) =>
      NumberFormat.decimalPercentPattern(
        locale: locale,
        decimalDigits: decimalDigits,
      );
}
