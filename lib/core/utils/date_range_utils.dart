import 'package:saydin/features/what_if/domain/entities/asset.dart';

/// Asset'e ait geçerli tarih aralığını döner.
/// [priceHistoryMonths] == 0 → sınırsız; [asset.firstDate]'den itibaren.
/// [priceHistoryMonths] > 0 → en erken seçilebilir tarih = lastDate - N ay.
({DateTime? firstDate, DateTime? lastDate}) assetDateRange({
  required DateTime? assetFirstDate,
  required DateTime? assetLastDate,
  required int priceHistoryMonths,
}) {
  final lastDate = assetLastDate ?? DateTime.now();

  if (priceHistoryMonths == 0) {
    if (assetFirstDate != null && assetFirstDate.isAfter(lastDate)) {
      return (firstDate: null, lastDate: null);
    }
    return (firstDate: assetFirstDate, lastDate: lastDate);
  }

  final cutoff = DateTime(
    lastDate.year,
    lastDate.month - priceHistoryMonths,
    lastDate.day,
  );

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
/// durumunda assertion fırlatır ve sayfa çöker. Bu yüzden invalid
/// kesişimde `(null, null)` dönülür — caller "aralık yok" mesajı veya
/// disable edilmiş DateInput göstermelidir.
({DateTime? firstDate, DateTime? lastDate}) comparisonDateRange({
  required List<Asset> assets,
  required List<String> selectedSymbols,
  required int priceHistoryMonths,
}) {
  if (selectedSymbols.isEmpty) return (firstDate: null, lastDate: null);

  final selected = assets
      .where((a) => selectedSymbols.contains(a.symbol))
      .toList();
  if (selected.isEmpty) return (firstDate: null, lastDate: null);

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
      return (firstDate: null, lastDate: null);
    }
    return (firstDate: firstDate, lastDate: lastDate);
  }

  final effectiveLast = lastDate ?? DateTime.now();
  final cutoff = DateTime(
    effectiveLast.year,
    effectiveLast.month - priceHistoryMonths,
    effectiveLast.day,
  );

  if (firstDate == null || cutoff.isAfter(firstDate)) {
    firstDate = cutoff;
  }

  // Son guard: cutoff lastDate'ten sonra olabilir (lastDate çok eskiyse).
  if (lastDate != null && firstDate.isAfter(lastDate)) {
    return (firstDate: null, lastDate: null);
  }

  return (firstDate: firstDate, lastDate: lastDate);
}
