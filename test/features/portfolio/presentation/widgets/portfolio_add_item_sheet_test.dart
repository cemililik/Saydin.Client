import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_add_item_sheet.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  const asset = Asset(
    symbol: 'USDTRY',
    displayName: 'Dolar/TL',
    category: 'currency',
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required void Function(Decimal amount) onSave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PortfolioAddItemSheet(
              assets: const [asset],
              editItem: PortfolioItem(
                id: 'id',
                assetSymbol: asset.symbol,
                assetDisplayName: asset.displayName,
                amount: Decimal.one,
                amountType: 'units',
              ),
              onSave:
                  ({
                    required assetSymbol,
                    required assetDisplayName,
                    required amount,
                    required amountType,
                  }) => onSave(amount),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('TR çok ondalıklı unit girdisi callbacke exact Decimal gider', (
    tester,
  ) async {
    Decimal? saved;
    await pumpSheet(tester, onSave: (amount) => saved = amount);

    await tester.enterText(find.byType(TextFormField), '0,12345678');
    await tester.tap(find.text('Kaydet'));
    await tester.pump();

    expect(saved, Decimal.parse('0.12345678'));
  });

  testWidgets('unit için sekizden fazla ondalık hane reddedilir', (
    tester,
  ) async {
    Decimal? saved;
    await pumpSheet(tester, onSave: (amount) => saved = amount);

    await tester.enterText(find.byType(TextFormField), '0,123456789');
    await tester.tap(find.text('Kaydet'));
    await tester.pump();

    expect(saved, isNull);
    expect(find.textContaining('en fazla 8 ondalık'), findsOneWidget);
  });
}
