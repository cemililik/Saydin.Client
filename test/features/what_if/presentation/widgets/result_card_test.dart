import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/result_card.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  WhatIfResult result({double? realPct, double? cumInfl}) => WhatIfResult(
    assetSymbol: 'USDTRY',
    assetDisplayName: 'Dolar/TL',
    buyDate: DateTime.utc(2021, 1, 1),
    sellDate: DateTime.utc(2022, 1, 1),
    buyPrice: Decimal.one,
    sellPrice: Decimal.fromInt(2),
    unitsAcquired: Decimal.fromInt(100),
    initialValueTry: Decimal.fromInt(100),
    finalValueTry: Decimal.fromInt(200),
    profitLossTry: Decimal.fromInt(100),
    profitLossPercent: 100,
    isProfit: true,
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
}
