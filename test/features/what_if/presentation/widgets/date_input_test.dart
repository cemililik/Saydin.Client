import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/presentation/widgets/date_input.dart';
import 'package:saydin/l10n/app_localizations.dart';

void main() {
  Widget subject({
    required ValueChanged<DateTime?> onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
  }) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(
      body: DateInput(
        label: 'Tarih',
        firstDate: firstDate ?? DateTime(2020),
        lastDate: lastDate ?? DateTime(2024),
        onChanged: onChanged,
      ),
    ),
  );

  testWidgets('picker iptalinde callback çağrılmaz', (tester) async {
    var callbackCount = 0;
    await tester.pumpWidget(subject(onChanged: (_) => callbackCount++));

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(callbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('geçersiz tarih aralığında alan disable olur ve dialog açmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        firstDate: DateTime(2024),
        lastDate: DateTime(2020),
        onChanged: (_) {},
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
