import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/constants/app_branding.dart';
import 'package:saydin/core/widgets/share_card_surface.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/presentation/widgets/comparison_share_card_widget.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/presentation/widgets/dca_share_card_widget.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_share_card_widget.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/reverse_share_card_widget.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  final buyDate = DateTime(2024, 1, 2);
  final sellDate = DateTime(2025, 1, 2);

  WhatIfResult whatIf({String name = 'Altın', double percent = 20}) =>
      WhatIfResult(
        assetSymbol: name,
        assetDisplayName: name,
        buyDate: buyDate,
        sellDate: sellDate,
        buyPrice: Decimal.fromInt(100),
        sellPrice: Decimal.fromInt(120),
        unitsAcquired: Decimal.fromInt(10),
        initialValueTry: Decimal.fromInt(1000),
        finalValueTry: Decimal.fromInt(1200),
        profitLossTry: Decimal.fromInt(200),
        profitLossPercent: percent,
        isProfit: true,
      );

  final reverse = ReverseWhatIfResult(
    assetSymbol: 'XAU',
    assetDisplayName: 'Altın',
    buyDate: buyDate,
    sellDate: sellDate,
    buyPrice: Decimal.fromInt(100),
    sellPrice: Decimal.fromInt(120),
    requiredInvestmentTry: Decimal.fromInt(1000),
    unitsAcquired: Decimal.fromInt(10),
    targetValueTry: Decimal.fromInt(1200),
    profitLossTry: Decimal.fromInt(200),
    profitLossPercent: 20,
    isProfit: true,
  );

  final portfolioItem = PortfolioItem(
    id: '1',
    assetSymbol: 'XAU',
    assetDisplayName: 'Altın',
    amount: Decimal.fromInt(1000),
    amountType: 'try',
  );
  final portfolio = PortfolioResult(
    items: [
      PortfolioItemResult(
        item: portfolioItem,
        calculation: PortfolioCalculation(
          initialValueTry: Decimal.fromInt(1000),
          finalValueTry: Decimal.fromInt(1200),
          profitLossPercent: 20,
          isProfit: true,
        ),
        sharePercent: 100,
      ),
    ],
    totalInitialValueTry: Decimal.fromInt(1000),
    totalFinalValueTry: Decimal.fromInt(1200),
    totalProfitLossTry: Decimal.fromInt(200),
    totalProfitLossPercent: 20,
    isProfit: true,
    effectiveSellDate: sellDate,
  );

  final dca = DcaResult(
    assetSymbol: 'XAU',
    assetDisplayName: 'Altın',
    startDate: buyDate,
    endDate: sellDate,
    period: 'monthly',
    periodicAmount: Decimal.fromInt(100),
    totalPurchases: 12,
    totalInvestedTry: Decimal.fromInt(1200),
    currentValueTry: Decimal.fromInt(1440),
    profitLossTry: Decimal.fromInt(240),
    profitLossPercent: 20,
    isProfit: true,
    averageCostPerUnit: Decimal.fromInt(100),
    totalUnitsAcquired: Decimal.fromInt(12),
    currentUnitPrice: Decimal.fromInt(120),
  );

  final cards = <(String, Widget)>[
    ('what-if', ShareCardWidget(result: whatIf())),
    ('reverse what-if', ReverseShareCardWidget(result: reverse)),
    (
      'comparison',
      ComparisonShareCardWidget(
        result: CompareResult(
          results: [
            CompareResultItem(rank: 1, calculation: whatIf()),
            CompareResultItem(
              rank: 2,
              calculation: whatIf(name: 'Dolar', percent: 10),
            ),
          ],
        ),
        buyDate: buyDate,
        sellDate: sellDate,
      ),
    ),
    (
      'portfolio',
      PortfolioShareCardWidget(
        result: portfolio,
        buyDate: buyDate,
        sellDate: sellDate,
      ),
    ),
    ('dca', DcaShareCardWidget(result: dca)),
  ];

  for (final (name, card) in cards) {
    testWidgets('$name card renders the approved logo through common surface', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(body: SingleChildScrollView(child: card)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShareCardSurface), findsOneWidget);
      final image = tester.widget<Image>(
        find.byKey(ShareCardBrandHeader.assetKey),
      );
      expect(
        (image.image as AssetImage).assetName,
        AppBranding.horizontalLogoOnLightAsset,
      );
      expect(find.text('saydın'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
