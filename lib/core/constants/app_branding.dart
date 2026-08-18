/// Marka sabitleri — paylaşım kartı görselinde kullanılan "saydın" sözcük
/// markası (wordmark) ve alan adı. Bu değerler **çevrilmez** (iki dilde de
/// aynı marka), bu yüzden ARB yerine sabit olarak tutulur (F-07-19).
///
/// Uygulama içi başlık/etiket olarak görünen marka adı için `l10n.appTitle`
/// kullanılır (çevrilebilir UI metni — burada değil).
class AppBranding {
  const AppBranding._();

  /// Paylaşım kartı üst köşesindeki küçük sözcük markası.
  static const String wordmark = 'saydın';

  /// Paylaşım kartı altbilgisindeki indirme/erişim adresi.
  static const String domain = 'saydın.app';
}
