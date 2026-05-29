/// Saf Dart tarih yardımcıları (Flutter bağımlılığı YOK — BLoC/domain'den
/// güvenle çağrılabilir).
///
/// Not: Flutter `material` paketindeki `DateUtils.isSameDay` ile karışmasın
/// diye bu top-level fonksiyon kasıtlı olarak sınıf altına alınmadı —
/// `material` import etmeyen katmanlarda (BLoC, domain) ek bağımlılık
/// getirmeden kullanılır.
library;

/// İki tarihi yalnızca yıl/ay/gün bazında karşılaştırır (saat bileşeni
/// yok sayılır).
///
/// - İkisi de `null` → `true` (ör. "satış tarihi yok" senaryosu eşleşmesi)
/// - Yalnızca biri `null` → `false`
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
