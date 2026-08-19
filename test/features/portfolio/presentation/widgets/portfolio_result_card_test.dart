import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_result_card.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  PortfolioItem item(String symbol) => PortfolioItem(
    id: symbol,
    assetSymbol: symbol,
    assetDisplayName: symbol,
    amount: Decimal.fromInt(100),
    amountType: 'try',
  );

  testWidgets('partial sonuç kapsamı ve typed hata açıkça gösterilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final successfulItem = item('AAA');
    final result = PortfolioResult(
      items: [
        PortfolioItemResult(
          item: successfulItem,
          calculation: PortfolioCalculation(
            initialValueTry: Decimal.fromInt(100),
            finalValueTry: Decimal.fromInt(120),
            profitLossPercent: 20,
            isProfit: true,
          ),
          sharePercent: 100,
        ),
      ],
      failures: [
        PortfolioItemFailure(item: item('BBB'), error: const NoInternetError()),
      ],
      totalInitialValueTry: Decimal.fromInt(100),
      totalFinalValueTry: Decimal.fromInt(120),
      totalProfitLossTry: Decimal.fromInt(20),
      totalProfitLossPercent: 20,
      isProfit: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PortfolioResultCard(result: result),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Bazı varlıklar hesaplanamadı'), findsOneWidget);
    expect(find.textContaining('BBB:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
