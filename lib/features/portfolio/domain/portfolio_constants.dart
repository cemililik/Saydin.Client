/// Portföy özelliğine özgü sabitler.
///
/// CLAUDE.md "Sabitler": magic number widget/BLoC içinde YASAK; merkezi sabit.
class PortfolioConstants {
  const PortfolioConstants._();

  /// Bir portföydeki en fazla kalem sayısı. Her kalem ayrı bir backend
  /// hesaplamasıdır (CalculatePortfolio `Future.wait`); sınır quota/fan-out
  /// suistimalini önler.
  static const int maxItems = 20;

  /// Tek kalem için kabul edilen üst tutar sınırı (1 milyar). Astronomik
  /// girişleri (ör. 999999999999999) eler.
  static const num maxItemAmount = 1000000000;
}
