/// Marka sabitleri. Bunlar **çevrilmez** (iki dilde de aynı marka), bu yüzden
/// ARB yerine sabit olarak tutulur (F-07-19).
///
/// Uygulama içi başlık/etiket olarak görünen marka adı için `l10n.appTitle`
/// kullanılır (çevrilebilir UI metni — burada değil).
class AppBranding {
  const AppBranding._();

  /// Erişilebilir marka adı. Görsel wordmark yerine `Text` ile çizilmez.
  static const String displayName = 'Saydın';

  /// Açık zemin üzerinde kullanılacak onaylı, şeffaf horizontal lockup.
  static const String horizontalLogoOnLightAsset =
      'assets/branding/saydin-logo-horizontal-light-h512.png';

  /// Koyu zemin üzerinde kullanılacak onaylı, şeffaf horizontal lockup.
  static const String horizontalLogoOnDarkAsset =
      'assets/branding/saydin-logo-horizontal-dark-h512.png';

  /// Dar alanlarda kullanılabilecek onaylı, şeffaf standalone sembol.
  static const String fullColorSymbolAsset =
      'assets/branding/saydin-symbol-fullcolor-256.png';

  /// UI ve export artifact'lerinde kullanılan bundled font family.
  static const String uiFontFamily = 'Inter';

  /// Paylaşım kartı altbilgisindeki indirme/erişim adresi.
  static const String domain = 'saydın.app';
}
