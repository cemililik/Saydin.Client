import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/theme/app_theme.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/presentation/widgets/dca_chart.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  final points = [
    DcaChartPoint(
      date: DateTime(2024, 1, 1),
      cumulativeCost: Decimal.fromInt(100),
      cumulativeValue: Decimal.fromInt(105),
    ),
    DcaChartPoint(
      date: DateTime(2024, 2, 1),
      cumulativeCost: Decimal.fromInt(200),
      cumulativeValue: Decimal.fromInt(240),
    ),
  ];

  Future<void> pumpChart(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
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
            child: DcaChart(chartData: points, isProfit: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'iki seriyi tek screen-reader özetinde ve veri listesinde verir',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpChart(tester);

      expect(
        find.bySemanticsLabel(RegExp('Düzenli yatırım grafiği')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('dca-chart-data-toggle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dca-chart-data-list')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('maliyet')), findsWidgets);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('veri alternatifi klavyeyle açılır ve 200% metinde taşmaz', (
    tester,
  ) async {
    await pumpChart(tester, textScale: 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dca-chart-data-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
