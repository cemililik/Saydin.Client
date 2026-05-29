/// Uygulama genelinde paylaşılan tarih sabitleri.
///
/// CLAUDE.md "Sabitler": magic number widget içinde YASAK; merkezi sabit kullan.
class DateConstants {
  const DateConstants._();

  /// Bir varlık `firstPriceDate` sunmadığında tarih seçicide kullanılan
  /// mutlak en erken seçilebilir tarih (taban). ~2010 öncesi fiyat verisi
  /// güvenilir değildir. `DateTime` const-constructible olmadığından `final`.
  static final DateTime earliestPriceDate = DateTime(2010);
}
