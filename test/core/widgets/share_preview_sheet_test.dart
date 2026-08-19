import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/share_card_renderer.dart';
import 'package:saydin/core/widgets/share_preview_sheet.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  testWidgets('share CTA global rect is forwarded as the iPad popover anchor', (
    tester,
  ) async {
    Rect? forwardedOrigin;
    final brandReady = Completer<void>();
    final shareFinished = Completer<void>();

    Future<ShareDeliveryResult> recordShare(
      GlobalKey repaintKey, {
      required String caption,
      required Rect viewport,
      required Rect sharePositionOrigin,
      required ShareAuthorization canExecuteShare,
    }) async {
      forwardedOrigin = sharePositionOrigin;
      await shareFinished.future;
      return ShareDeliveryResult.completed;
    }

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SharePreviewSheet(
            brandAssetReady: brandReady.future,
            shareAction: recordShare,
            canExecuteShare: () => true,
            cardWidget: const ColoredBox(
              color: Colors.white,
              child: SizedBox(width: 540, height: 300),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final shareButton = find.byType(FilledButton);
    await tester.tap(shareButton);
    await tester.pump();
    expect(forwardedOrigin, isNull);

    brandReady.complete();
    await tester.pump();
    final actualButtonRect = tester.getRect(shareButton);

    expect(forwardedOrigin, isNotNull);
    expect(forwardedOrigin!.isFinite, isTrue);
    expect(forwardedOrigin!.isEmpty, isFalse);
    expect(forwardedOrigin, actualButtonRect);

    shareFinished.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('flag flip after preview opens blocks the share action', (
    tester,
  ) async {
    var canExecute = true;
    var invocationCount = 0;
    ShareDeliveryResult? observedResult;

    Future<ShareDeliveryResult> recordShare(
      GlobalKey repaintKey, {
      required String caption,
      required Rect viewport,
      required Rect sharePositionOrigin,
      required ShareAuthorization canExecuteShare,
    }) async {
      invocationCount++;
      return ShareDeliveryResult.completed;
    }

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SharePreviewSheet(
            brandAssetReady: Future<void>.value(),
            shareAction: recordShare,
            canExecuteShare: () => canExecute,
            onShareResult: (result) => observedResult = result,
            cardWidget: const ColoredBox(
              color: Colors.white,
              child: SizedBox(width: 540, height: 300),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    canExecute = false;
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(invocationCount, 0);
    expect(observedResult, ShareDeliveryResult.denied);
  });

  testWidgets(
    'preview freezes and forwards the exact visible caption including CTA',
    (tester) async {
      String? deliveredCaption;
      ShareDeliveryResult? observedResult;

      Future<ShareDeliveryResult> recordShare(
        GlobalKey repaintKey, {
        required String caption,
        required Rect viewport,
        required Rect sharePositionOrigin,
        required ShareAuthorization canExecuteShare,
      }) async {
        deliveredCaption = caption;
        return ShareDeliveryResult.dismissed;
      }

      Widget app(Locale locale) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: SharePreviewSheet(
            brandAssetReady: Future<void>.value(),
            shareAction: recordShare,
            onShareResult: (result) => observedResult = result,
            shareText: '  Temel metin\n',
            canExecuteShare: () => true,
            cardWidget: const ColoredBox(
              color: Colors.white,
              child: SizedBox(width: 540, height: 300),
            ),
          ),
        ),
      );

      final tr = await AppLocalizations.delegate.load(const Locale('tr'));
      final expected = '  Temel metin\n${tr.shareCta}';
      await tester.pumpWidget(app(const Locale('tr')));
      await tester.pumpAndSettle();

      expect(find.text(expected), findsOneWidget);

      // Aynı preview oturumunda locale değişse bile gösterilen/delivered
      // caption revizyonu sessizce değişmez.
      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(deliveredCaption, expected);
      expect(observedResult, ShareDeliveryResult.dismissed);
    },
  );

  testWidgets('typed denied result does not show a render error', (
    tester,
  ) async {
    Future<ShareDeliveryResult> denyShare(
      GlobalKey repaintKey, {
      required String caption,
      required Rect viewport,
      required Rect sharePositionOrigin,
      required ShareAuthorization canExecuteShare,
    }) async => ShareDeliveryResult.denied;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SharePreviewSheet(
            brandAssetReady: Future<void>.value(),
            shareAction: denyShare,
            canExecuteShare: () => true,
            cardWidget: const SizedBox(width: 540, height: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('route disposal revokes the deferred pre-gateway authorization', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final renderGate = Completer<void>();
    bool? preGatewayAuthorized;
    var nativeUiOpenCount = 0;

    Future<ShareDeliveryResult> deferredShare(
      GlobalKey repaintKey, {
      required String caption,
      required Rect viewport,
      required Rect sharePositionOrigin,
      required ShareAuthorization canExecuteShare,
    }) async {
      await renderGate.future;
      preGatewayAuthorized = canExecuteShare();
      if (preGatewayAuthorized!) nativeUiOpenCount++;
      return preGatewayAuthorized!
          ? ShareDeliveryResult.completed
          : ShareDeliveryResult.denied;
    }

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => SharePreviewSheet(
                  brandAssetReady: Future<void>.value(),
                  caption: 'frozen caption',
                  shareAction: deferredShare,
                  canExecuteShare: () => true,
                  cardWidget: const SizedBox(width: 540, height: 300),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-preview-share')));
    await tester.pump();

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    renderGate.complete();
    await tester.pump();

    expect(preGatewayAuthorized, isFalse);
    expect(nativeUiOpenCount, 0);
  });

  testWidgets('copy is explicit and uses the exact frozen final caption', (
    tester,
  ) async {
    const frozenCaption = '  Exact caption\n\nCTA #saydın  ';
    final copiedCaptions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SharePreviewSheet(
            brandAssetReady: Future<void>.value(),
            caption: frozenCaption,
            copyAction: (caption) async => copiedCaptions.add(caption),
            canExecuteShare: () => true,
            cardWidget: const SizedBox(width: 540, height: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(copiedCaptions, isEmpty);
    expect(find.text(frozenCaption), findsOneWidget);

    await tester.tap(find.byKey(const Key('share-preview-copy')));
    await tester.pump();

    expect(copiedCaptions, [frozenCaption]);
    expect(find.text('Sharing text copied.'), findsOneWidget);
  });

  testWidgets('Ctrl+C copies and Escape closes the preview route', (
    tester,
  ) async {
    final copiedCaptions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => SharePreviewSheet(
                  brandAssetReady: Future<void>.value(),
                  caption: 'keyboard caption',
                  copyAction: (caption) async => copiedCaptions.add(caption),
                  canExecuteShare: () => true,
                  cardWidget: const SizedBox(width: 540, height: 300),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(copiedCaptions, ['keyboard caption']);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('share-preview-interactive')), findsNothing);
  });

  testWidgets('unavailable is recoverable and is not reported as an error', (
    tester,
  ) async {
    ShareDeliveryResult? observedResult;
    var reportCount = 0;

    Future<ShareDeliveryResult> unavailableShare(
      GlobalKey repaintKey, {
      required String caption,
      required Rect viewport,
      required Rect sharePositionOrigin,
      required ShareAuthorization canExecuteShare,
    }) async => ShareDeliveryResult.unavailable;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SharePreviewSheet(
            brandAssetReady: Future<void>.value(),
            shareAction: unavailableShare,
            errorReportAction: (_, _, {required context}) async {
              reportCount++;
            },
            onShareResult: (result) => observedResult = result,
            canExecuteShare: () => true,
            cardWidget: const SizedBox(width: 540, height: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-preview-share')));
    await tester.pumpAndSettle();

    expect(observedResult, ShareDeliveryResult.unavailable);
    expect(
      find.text(
        "Sharing isn't available on this device. You can copy the text instead.",
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('share-preview-copy')))
          .onPressed,
      isNotNull,
    );
    expect(reportCount, 0);
  });

  testWidgets('error feedback renders before non-blocking safe reporting', (
    tester,
  ) async {
    final reportCompleter = Completer<void>();
    var reportStarted = false;
    String? reportedError;
    String? reportedContext;

    Future<ShareDeliveryResult> failingShare(
      GlobalKey repaintKey, {
      required String caption,
      required Rect viewport,
      required Rect sharePositionOrigin,
      required ShareAuthorization canExecuteShare,
    }) async => throw StateError('must not reach telemetry: 10,000 TRY');

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SharePreviewSheet(
            brandAssetReady: Future<void>.value(),
            caption: 'private financial caption',
            shareAction: failingShare,
            errorReportAction: (error, _, {required context}) {
              expect(
                find.text("Couldn't create the share card. Please try again."),
                findsOneWidget,
              );
              reportStarted = true;
              reportedError = error.toString();
              reportedContext = context;
              return reportCompleter.future;
            },
            canExecuteShare: () => true,
            cardWidget: const SizedBox(width: 540, height: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-preview-share')));
    await tester.pump();
    await tester.pump();

    expect(reportStarted, isTrue);
    expect(reportedContext, 'share_card');
    expect(reportedError, isNot(contains('10,000')));
    expect(reportedError, isNot(contains('private financial caption')));
    expect(find.byKey(const Key('share-preview-copy')), findsOneWidget);

    reportCompleter.complete();
  });

  testWidgets('preview semantics summarize the excluded raw card subtree', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SharePreviewSheet(
            brandAssetReady: Future<void>.value(),
            caption: 'Accessible final caption',
            canExecuteShare: () => true,
            cardWidget: const SizedBox(
              width: 540,
              height: 300,
              child: Text('Raw duplicated card value'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final previewData = tester
        .getSemantics(find.byKey(const Key('share-preview-interactive')))
        .getSemanticsData();
    expect(previewData.label, 'Preview of the card that will be shared');
    expect(previewData.label, isNot(contains('Raw duplicated card value')));
    expect(find.bySemanticsLabel('Raw duplicated card value'), findsNothing);
    expect(
      tester
          .getSemantics(find.text('Share Preview'))
          .getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );
    final closeData = tester
        .getSemantics(find.byKey(const Key('share-preview-close')))
        .getSemanticsData();
    expect(closeData.label, contains('Close share preview'));
    expect(
      tester.getSize(find.byKey(const Key('share-preview-close'))),
      const Size(48, 48),
    );
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'share-preview-close',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'share-preview-caption',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'share-preview-copy',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'share-preview-share',
    );
    semantics.dispose();
  });

  testWidgets('320x568 at 300% keeps every decision action reachable', (
    tester,
  ) async {
    final shareGate = Completer<ShareDeliveryResult>();
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(3),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SharePreviewSheet(
              brandAssetReady: Future<void>.value(),
              caption: 'Accessible final caption with enough text to wrap.',
              shareAction:
                  (
                    _, {
                    required caption,
                    required viewport,
                    required sharePositionOrigin,
                    required canExecuteShare,
                  }) => shareGate.future,
              canExecuteShare: () => true,
              cardWidget: const SizedBox(width: 540, height: 675),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final closeFinder = find.byKey(const Key('share-preview-close'));
    expect(closeFinder.hitTestable(), findsOneWidget);
    for (final key in const <Key>[
      Key('share-preview-copy'),
      Key('share-preview-share'),
    ]) {
      final finder = find.byKey(key);
      expect(finder, findsOneWidget);
      await tester.ensureVisible(finder);
      await tester.pump();
      expect(finder.hitTestable(), findsOneWidget);
      final rect = tester.getRect(finder);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(568));
      expect(closeFinder.hitTestable(), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('share-preview-share')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const Key('share-preview-caption'))),
      ).scale(10),
      30,
    );
    expect(
      tester
          .widget<InteractiveViewer>(
            find.byKey(const Key('share-preview-interactive')),
          )
          .maxScale,
      greaterThanOrEqualTo(4),
    );

    shareGate.complete(ShareDeliveryResult.dismissed);
    await tester.pump();
  });
}
