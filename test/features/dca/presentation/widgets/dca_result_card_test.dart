import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/presentation/widgets/dca_result_card.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  DcaResult result({double? realPct, double? cumulativeInflation}) => DcaResult(
    assetSymbol: 'USDTRY',
    assetDisplayName: 'Dolar/TL',
    startDate: DateTime(2021),
    endDate: DateTime(2022),
    period: 'monthly',
    periodicAmount: Decimal.fromInt(100),
    totalPurchases: 12,
    totalInvestedTry: Decimal.fromInt(1200),
    currentValueTry: Decimal.fromInt(1500),
    profitLossTry: Decimal.fromInt(300),
    profitLossPercent: 25,
    isProfit: true,
    averageCostPerUnit: Decimal.one,
    totalUnitsAcquired: Decimal.fromInt(1200),
    currentUnitPrice: Decimal.fromInt(2),
    realProfitLossPercent: realPct,
    cumulativeInflationPercent: cumulativeInflation,
  );

  Future<void> pump(WidgetTester tester, DcaResult value) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(child: DcaResultCard(result: value)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('real yüzde tek başına geldiğinde crash olmaz', (tester) async {
    await pump(tester, result(realPct: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('birikimli enflasyon tek başına geldiğinde crash olmaz', (
    tester,
  ) async {
    await pump(tester, result(cumulativeInflation: 50));
    expect(tester.takeException(), isNull);
  });
}
