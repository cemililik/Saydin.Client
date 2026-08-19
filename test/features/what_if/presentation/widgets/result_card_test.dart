import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/result_card.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  WhatIfResult result({
    double? realPct,
    double? cumInfl,
    Decimal? profitLossTry,
    double profitLossPercent = 100,
    bool isProfit = true,
  }) => WhatIfResult(
    assetSymbol: 'USDTRY',
    assetDisplayName: 'Dolar/TL',
    buyDate: DateTime.utc(2021, 1, 1),
    sellDate: DateTime.utc(2022, 1, 1),
    buyPrice: Decimal.one,
    sellPrice: Decimal.fromInt(2),
    unitsAcquired: Decimal.fromInt(100),
    initialValueTry: Decimal.fromInt(100),
    finalValueTry: Decimal.fromInt(200),
    profitLossTry: profitLossTry ?? Decimal.fromInt(100),
    profitLossPercent: profitLossPercent,
    isProfit: isProfit,
    realProfitLossPercent: realPct,
    cumulativeInflationPercent: cumInfl,
  );

  Future<void> pumpCard(WidgetTester tester, WhatIfResult r) async {
    // Geniş+uzun yüzey → ilgisiz layout-overflow exception'ı M2 assertion'ını
    // kirletmesin.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(child: ResultCard(result: r)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  group('ResultCard — M2 divergent-null enflasyon', () {
    testWidgets('build_realPctSetCumulativeInflationNull_doesNotCrash', (
      tester,
    ) async {
      // Eski kod: enflasyon bölümü realProfitLossPercent!=null ile gate'li
      // ama cumulativeInflationPercent! dereference ediyordu → null-check crash.
      await pumpCard(tester, result(realPct: -10, cumInfl: null));
      expect(tester.takeException(), isNull);
    });

    testWidgets('build_bothInflationFieldsSet_doesNotCrash', (tester) async {
      await pumpCard(tester, result(realPct: -10, cumInfl: 85));
      expect(tester.takeException(), isNull);
    });

    testWidgets('build_noInflationFields_doesNotCrash', (tester) async {
      await pumpCard(tester, result());
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('sıfır getiri kâr/zarar yerine neutral gösterilir', (
    tester,
  ) async {
    final neutral = result(
      profitLossTry: Decimal.zero,
      profitLossPercent: 0,
      // Legacy backend alanı true gelse bile exact tutar otoritatiftir.
      isProfit: true,
    );

    await pumpCard(tester, neutral);

    expect(find.text('Değişim Yok'), findsOneWidget);
    expect(find.text('Değişim'), findsOneWidget);
    expect(find.text('Kazanç'), findsNothing);
    expect(find.text('Kayıp'), findsNothing);
  });

  testWidgets('sıfır getiri paylaşım artifactinde neutral anlatılır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final neutral = result(
      profitLossTry: Decimal.zero,
      profitLossPercent: 0,
      isProfit: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(body: ShareCardWidget(result: neutral)),
      ),
    );

    expect(find.textContaining('değişim yok'), findsOneWidget);
    expect(find.textContaining('+%0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
