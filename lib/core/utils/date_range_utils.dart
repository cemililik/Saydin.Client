import 'package:saydin/features/what_if/domain/entities/asset.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// [months] takvim ayını çıkarır ve kaynak gün hedef ayda yoksa ayın son
/// gününe clamp eder. Dart'ın `DateTime(y, m, day)` taşma davranışının
/// 31 Mart - 1 ayı Mart'a geri taşımasını engeller.
DateTime subtractCalendarMonthsClamped(DateTime value, int months) {
  if (months < 0) {
    throw ArgumentError.value(months, 'months', 'negatif olamaz');
  }
  final source = _dateOnly(value);
  final zeroBasedTargetMonth = source.year * 12 + source.month - 1 - months;
  final targetYear = zeroBasedTargetMonth ~/ 12;
  final targetMonth = zeroBasedTargetMonth % 12 + 1;
  final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
  final targetDay = source.day > lastDay ? lastDay : source.day;
  return DateTime(targetYear, targetMonth, targetDay);
}

bool isValidFinancialDateRange(DateTime start, DateTime? end) =>
    end == null || !_dateOnly(end).isBefore(_dateOnly(start));

/// Asset'e ait geçerli tarih aralığını döner.
/// [priceHistoryMonths] == 0 → sınırsız; [asset.firstDate]'den itibaren.
/// [priceHistoryMonths] > 0 → en erken seçilebilir tarih = lastDate - N ay.
({DateTime? firstDate, DateTime? lastDate}) assetDateRange({
  required DateTime? assetFirstDate,
  required DateTime? assetLastDate,
  required int priceHistoryMonths,
}) {
  final lastDate = _dateOnly(assetLastDate ?? DateTime.now());

  if (priceHistoryMonths == 0) {
    if (assetFirstDate != null && assetFirstDate.isAfter(lastDate)) {
      return (firstDate: null, lastDate: null);
    }
    return (firstDate: assetFirstDate, lastDate: lastDate);
  }

  if (priceHistoryMonths < 0) {
    return (firstDate: null, lastDate: null);
  }
  final cutoff = subtractCalendarMonthsClamped(lastDate, priceHistoryMonths);

  final firstDate = assetFirstDate == null || cutoff.isAfter(assetFirstDate)
      ? cutoff
      : assetFirstDate;

  // Guard: cutoff lastDate'ten sonra olabilir (priceHistoryMonths negatif
  // veya lastDate çok eski). `showDatePicker` assertion crash önlenir.
  if (firstDate.isAfter(lastDate)) {
    return (firstDate: null, lastDate: null);
  }

  return (firstDate: firstDate, lastDate: lastDate);
}

/// Seçili varlıkların tarih aralıklarının kesişimini hesaplar,
/// ardından [priceHistoryMonths] kısıtını uygular.
///
/// İki ayrı varlığın aralıkları örtüşmüyorsa (örn BTC: 2021-01..2024-01,
/// XYZ: 2024-06..2024-09), kesişim başlangıcı (`firstDate`) bitişinden
/// (`lastDate`) sonra düşer. `showDatePicker` `firstDate > lastDate`
/// durumunda assertion fırlatır ve sayfa çöker. Bu yüzden invalid kesişim
/// [ComparisonDateRange.hasOverlap] ile açıkça temsil edilir; caller tarih
/// alanlarını disable edip kullanıcıya nedenini göstermelidir.
class ComparisonDateRange {
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool hasOverlap;

  const ComparisonDateRange({
    required this.firstDate,
    required this.lastDate,
    required this.hasOverlap,
  });
}

ComparisonDateRange comparisonDateRange({
  required List<Asset> assets,
  required List<String> selectedSymbols,
  required int priceHistoryMonths,
}) {
  if (selectedSymbols.isEmpty) {
    return const ComparisonDateRange(
      firstDate: null,
      lastDate: null,
      hasOverlap: false,
    );
  }

  final selected = assets
      .where((a) => selectedSymbols.contains(a.symbol))
      .toList();
  if (selected.length != selectedSymbols.length) {
    return const ComparisonDateRange(
      firstDate: null,
      lastDate: null,
      hasOverlap: false,
    );
  }

  // Kesişim başlangıcı: firstDate'lerin maksimumu
  DateTime? firstDate;
  for (final a in selected) {
    if (a.firstDate != null) {
      if (firstDate == null || a.firstDate!.isAfter(firstDate)) {
        firstDate = a.firstDate;
      }
    }
  }

  // Kesişim sonu: lastDate'lerin minimumu
  DateTime? lastDate;
  for (final a in selected) {
    if (a.lastDate != null) {
      if (lastDate == null || a.lastDate!.isBefore(lastDate)) {
        lastDate = a.lastDate;
      }
    }
  }

  if (priceHistoryMonths == 0) {
    if (firstDate != null && lastDate != null && firstDate.isAfter(lastDate)) {
      return const ComparisonDateRange(
        firstDate: null,
        lastDate: null,
        hasOverlap: false,
      );
    }
    return ComparisonDateRange(
      firstDate: firstDate,
      lastDate: lastDate,
      hasOverlap: true,
    );
  }

  if (priceHistoryMonths < 0) {
    return const ComparisonDateRange(
      firstDate: null,
      lastDate: null,
      hasOverlap: false,
    );
  }
  final effectiveLast = _dateOnly(lastDate ?? DateTime.now());
  final cutoff = subtractCalendarMonthsClamped(
    effectiveLast,
    priceHistoryMonths,
  );

  if (firstDate == null || cutoff.isAfter(firstDate)) {
    firstDate = cutoff;
  }

  // Son guard: cutoff lastDate'ten sonra olabilir (lastDate çok eskiyse).
  if (lastDate != null && firstDate.isAfter(lastDate)) {
    return const ComparisonDateRange(
      firstDate: null,
      lastDate: null,
      hasOverlap: false,
    );
  }

  return ComparisonDateRange(
    firstDate: firstDate,
    lastDate: lastDate,
    hasOverlap: true,
  );
}
