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
