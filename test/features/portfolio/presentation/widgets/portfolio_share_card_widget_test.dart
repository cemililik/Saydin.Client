import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/theme/app_theme.dart';
import 'package:saydin/core/widgets/share_preview_sheet.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_share_card_widget.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  PortfolioResult result({int itemCount = 20}) {
    final items = List.generate(itemCount, (index) {
      final item = PortfolioItem(
        id: '$index',
        assetSymbol: 'ASSET$index',
        assetDisplayName:
            'Çok uzun ve erişilebilir portföy varlığı adı numara $index',
        amount: Decimal.fromInt(100),
        amountType: 'try',
      );
      return PortfolioItemResult(
        item: item,
        calculation: PortfolioCalculation(
          initialValueTry: Decimal.fromInt(100),
          finalValueTry: Decimal.fromInt(120),
          profitLossPercent: 20,
          isProfit: true,
        ),
        sharePercent: 100 / itemCount,
      );
    });
    return PortfolioResult(
      items: items,
      totalInitialValueTry: Decimal.fromInt(itemCount * 100),
      totalFinalValueTry: Decimal.fromInt(itemCount * 120),
      totalProfitLossTry: Decimal.fromInt(itemCount * 20),
      totalProfitLossPercent: 20,
      isProfit: true,
      effectiveSellDate: DateTime(2024, 12, 31),
    );
  }

  Future<void> pumpPreview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SharePreviewSheet(
            cardWidget: PortfolioShareCardWidget(
              result: result(),
              buyDate: DateTime(2020, 1, 1),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('20 kalemi özetler; 320dp ve 200% metinde taşmaz', (
    tester,
  ) async {
    await pumpPreview(tester);

    expect(find.text('+14 varlık daha'), findsOneWidget);
    expect(find.textContaining('numara 0'), findsOneWidget);
    expect(find.textContaining('numara 6'), findsNothing);
    expect(find.text('Paylaş'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'uzun varlık adları capture kartında tek satır ellipsis kullanır',
    (tester) async {
      await pumpPreview(tester);

      final assetText = tester.widget<Text>(find.textContaining('numara 0'));
      expect(assetText.maxLines, 1);
      expect(assetText.overflow, TextOverflow.ellipsis);
    },
  );

  testWidgets('açık uçlu paylaşım tarihi sonuç snapshotından gelir', (
    tester,
  ) async {
    await pumpPreview(tester);

    expect(find.textContaining('31.12.2024'), findsWidgets);
  });

  testWidgets('maksimum portföy paylaşım kartı golden smoke', (tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: RepaintBoundary(
                key: const ValueKey('portfolio-share-golden'),
                child: PortfolioShareCardWidget(
                  result: result(),
                  buyDate: DateTime(2020, 1, 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('portfolio-share-golden')),
      matchesGoldenFile('goldens/portfolio_share_card_20_items.png'),
    );
  });
}
