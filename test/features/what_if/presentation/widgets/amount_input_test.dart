import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/presentation/widgets/amount_input.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  Widget subject(Locale locale, TextEditingController controller) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: AmountInput(
          controller: controller,
          amountType: 'try',
          allowedTypes: const ['try'],
          onAmountTypeChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('didChangeDependencies_trToEn_preservesAmountMagnitude', (
    tester,
  ) async {
    final controller = TextEditingController(text: '1234,5');
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(const Locale('tr', 'TR'), controller));
    await tester.pumpWidget(subject(const Locale('en', 'US'), controller));
    await tester.pump();

    expect(controller.text, '1234.5');
  });

  testWidgets('didChangeDependencies_enToTr_preservesAmountMagnitude', (
    tester,
  ) async {
    final controller = TextEditingController(text: '1234.5');
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(const Locale('en', 'US'), controller));
    await tester.pumpWidget(subject(const Locale('tr', 'TR'), controller));
    await tester.pump();

    expect(controller.text, '1234,5');
  });
}
