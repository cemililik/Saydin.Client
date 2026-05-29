import 'package:saydin/l10n/app_localizations.dart';

/// İki tarih arasındaki süreyi locale'e göre etiketler ("3 gün", "5 ay",
/// "2 yıl 3 ay").
///
/// **Tek kaynak (F-07-20):** Önceden iki tutarsız algoritma vardı — sonuç
/// kartlarında 30/365 gün-eşiği, paylaşım kartlarında takvim-ayı matematiği —
/// ve aynı tarih aralığı kart ile paylaşım kartında FARKLI süre gösterebiliyordu
/// (örn. 31 Oca → 1 Mar: "1 ay" vs "2 ay"). Takvim-ayı bazlı tek algoritma
/// benimsendi (ay sınırlarını geçen aralık takvim aylarını yansıtır).
class DurationLabel {
  const DurationLabel._();

  /// [start]–[end] arası süre etiketi. [end] null ise bugün (yerel, date-only).
  static String format(AppLocalizations l10n, DateTime start, DateTime? end) {
    final e = end ?? _todayLocal();
    final months = (e.year - start.year) * 12 + e.month - start.month;
    if (months < 1) {
      return l10n.durationDays(e.difference(start).inDays.abs());
    }
    if (months < 12) return l10n.durationMonths(months);
    final years = months ~/ 12;
    final remMonths = months % 12;
    return remMonths > 0
        ? l10n.durationYearsMonths(years, remMonths)
        : l10n.durationYears(years);
  }

  static DateTime _todayLocal() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}
