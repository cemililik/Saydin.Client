import 'package:flutter/material.dart';
import 'package:saydin/core/constants/app_branding.dart';
import 'package:saydin/core/constants/brand_colors.dart';

/// Bütün paylaşım kartlarının ortak marka yüzeyi.
///
/// Header'ın beş feature içinde kopyalanmasını önler; gerçek outline lockup,
/// resmi renkler ve bundled tipografi tek bir sözleşmeden uygulanır.
class ShareCardSurface extends StatelessWidget {
  static const double logicalWidth = 540;

  final List<Widget> children;

  const ShareCardSurface({super.key, required this.children});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: logicalWidth,
    child: DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: AppBranding.uiFontFamily,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: ShareCardColors.canvas),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 6,
              child: ColoredBox(color: BrandColors.teal),
            ),
            const ShareCardBrandHeader(),
            const SizedBox(
              height: 1,
              child: ColoredBox(color: ShareCardColors.divider),
            ),
            ...children,
          ],
        ),
      ),
    ),
  );
}

/// Açık paylaşım kartı üzerinde kullanılan onaylı horizontal marka lockup'ı.
class ShareCardBrandHeader extends StatelessWidget {
  static const assetKey = ValueKey<String>('share-card-brand-lockup');

  const ShareCardBrandHeader({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
    child: Center(
      child: Semantics(
        image: true,
        label: AppBranding.displayName,
        child: Image.asset(
          AppBranding.horizontalLogoOnLightAsset,
          key: assetKey,
          height: 44,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
