import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/constants/app_branding.dart';
import 'package:saydin/core/widgets/share_card_surface.dart';

void main() {
  Future<void> pumpSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: ValueKey<String>('share-card-boundary'),
            child: ShareCardSurface(
              children: <Widget>[
                Padding(padding: EdgeInsets.all(24), child: Text('123.456,78')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('uses the approved horizontal logo asset and semantics', (
    tester,
  ) async {
    await pumpSurface(tester);

    final image = tester.widget<Image>(
      find.byKey(ShareCardBrandHeader.assetKey),
    );
    final provider = image.image as AssetImage;
    expect(provider.assetName, AppBranding.horizontalLogoOnLightAsset);
    expect(find.text('saydın'), findsNothing);
    expect(find.bySemanticsLabel(AppBranding.displayName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locks export typography and renders at 1080 px width', (
    tester,
  ) async {
    await pumpSurface(tester);

    final numberText = find.text('123.456,78');
    final inheritedStyle = DefaultTextStyle.of(
      tester.element(numberText),
    ).style;
    expect(inheritedStyle.fontFamily, AppBranding.uiFontFamily);
    expect(
      inheritedStyle.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey<String>('share-card-boundary')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    addTearDown(image.dispose);
    expect(image.width, 1080);
    expect(image.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
