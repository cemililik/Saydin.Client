import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/theme/app_theme.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/result_chart.dart';
import 'package:saydin/core/utils/financial_outcome.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  final history = [
    ChartPoint(date: DateTime(2024, 1, 1), price: Decimal.fromInt(100)),
    ChartPoint(date: DateTime(2024, 2, 1), price: Decimal.fromInt(125)),
    ChartPoint(date: DateTime(2024, 3, 1), price: Decimal.fromInt(150)),
  ];

  Future<void> pumpChart(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ResultChart(
              priceHistory: history,
              outcome: FinancialOutcome.profit,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('screen reader için özet ve veri satırları sunar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpChart(tester);

    expect(find.bySemanticsLabel(RegExp('Fiyat grafiği')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('price-chart-data-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('price-chart-data-list')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('01.01.2024')), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('veri alternatifi klavyeyle açılır ve 200% metinde taşmaz', (
    tester,
  ) async {
    await pumpChart(tester, brightness: Brightness.dark, textScale: 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('price-chart-data-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
