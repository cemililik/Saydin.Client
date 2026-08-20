import 'package:flutter/material.dart';

/// Onaylı Saydın kimliği ve paylaşım artifact'i için sabit renk tokenları.
///
/// Uygulamanın mevcut Material seed renginden bağımsız tutulur. Böylece
/// sosyal artifact native icon/splash ile aynı marka dilini taşırken global
/// uygulama temasının aşamalı migrasyonu ayrıca yapılabilir.
class BrandColors {
  const BrandColors._();

  static const navy = Color(0xFF0B1D34);
  static const teal = Color(0xFF2CB1B8);
  static const offWhite = Color(0xFFF5F6F7);

  /// Açık zeminde WCAG AA sağlayan teal varyantı. `teal` yalnız koyu zeminde
  /// (navy kart, dark tema) okunabilir; açık yüzeyde 2,5:1'de kalarak hem
  /// 4,5:1 metin hem 3:1 non-text eşiğinin altına düşer.
  static const tealOnLight = Color(0xFF127C82);

  /// Marka gradient'lerinin ikinci durakları ve onboarding aksan tonu.
  static const navyCardEnd = Color(0xFF123D4B);
  static const ctaGradientEnd = Color(0xFF164354);
  static const steelAccent = Color(0xFF4678A9);

  /// Marka yüzeylerinde kullanılan nötr gölge/scrim tonu.
  static const scrim = Color(0x33000000);

  /// Zemin parlaklığına göre okunabilir teal tonunu verir.
  static Color tealFor(Brightness brightness) =>
      brightness == Brightness.dark ? teal : tealOnLight;
}

/// Açık renk paylaşım kartının erişilebilir surface/text tokenları.
class ShareCardColors {
  const ShareCardColors._();

  static const canvas = Colors.white;
  static const textPrimary = BrandColors.navy;
  static const textSecondary = Color(0xFF4F5E6D);
  static const iconMuted = Color(0xFF6B7886);
  static const divider = Color(0xFFDDE3E8);
  static const surfaceSubtle = BrandColors.offWhite;
  static const surfaceRaised = Color(0xFFF8FAFB);
  static const brandSurface = Color(0xFFE9F7F8);
  static const brandBorder = Color(0xFFA9DBDE);
}
