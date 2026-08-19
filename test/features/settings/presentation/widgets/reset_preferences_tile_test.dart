import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/features/settings/domain/usecases/reset_local_preferences.dart';
import 'package:saydin/features/settings/presentation/widgets/reset_preferences_tile.dart';
import 'package:saydin/l10n/app_localizations.dart';

class _MockResetLocalPreferences extends Mock
    implements ResetLocalPreferences {}

class _MockErrorReporter extends Mock implements ErrorReporter {}

void main() {
  late _MockResetLocalPreferences resetPreferences;
  late _MockErrorReporter reporter;
  late AppLifecycleEvents lifecycleEvents;

  setUpAll(() => registerFallbackValue(StackTrace.empty));

  setUp(() async {
    await sl.reset();
    resetPreferences = _MockResetLocalPreferences();
    reporter = _MockErrorReporter();
    lifecycleEvents = AppLifecycleEvents();
    sl
      ..registerSingleton<ResetLocalPreferences>(resetPreferences)
      ..registerSingleton<ErrorReporter>(reporter)
      ..registerSingleton<AppLifecycleEvents>(lifecycleEvents);
    when(() => resetPreferences()).thenAnswer((_) async {});
    when(
      () => reporter.report(any(), any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await lifecycleEvents.dispose();
    await sl.reset();
  });

  Future<void> pumpTile(WidgetTester tester, {double textScale = 1}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: ResetPreferencesTile()),
      ),
    );
  }

  Future<void> openConfirmation(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('reset-preferences-tile')));
    await tester.pumpAndSettle();
  }

  testWidgets('explains scope and resets the active app session on confirm', (
    tester,
  ) async {
    var resetEventCount = 0;
    final subscription = lifecycleEvents.resetStream.listen(
      (_) => resetEventCount++,
    );
    addTearDown(subscription.cancel);
    await pumpTile(tester);

    await openConfirmation(tester);

    expect(find.text('Yerel ayarlar sıfırlansın mı?'), findsOneWidget);
    expect(find.textContaining('Hesabınız'), findsOneWidget);
    expect(
      find.textContaining('Uygulama tanıtımı yeniden gösterilir'),
      findsOneWidget,
    );
    expect(
      find.textContaining('kaydedilmiş senaryolarınız silinmez'),
      findsOneWidget,
    );

    await tester.tap(find.text('Ayarları Sıfırla'));
    await tester.pumpAndSettle();

    verify(() => resetPreferences()).called(1);
    expect(resetEventCount, 1);
  });

  testWidgets('cancel leaves local preferences untouched', (tester) async {
    await pumpTile(tester);

    await openConfirmation(tester);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    verifyNever(() => resetPreferences());
  });

  testWidgets(
    'storage failure is reported and shown without resetting session',
    (tester) async {
      when(
        () => resetPreferences(),
      ).thenThrow(StateError('storage unavailable'));
      var resetEventCount = 0;
      final subscription = lifecycleEvents.resetStream.listen(
        (_) => resetEventCount++,
      );
      addTearDown(subscription.cancel);
      await pumpTile(tester);

      await openConfirmation(tester);
      await tester.tap(find.text('Ayarları Sıfırla'));
      await tester.pumpAndSettle();

      expect(
        find.text('Yerel ayarlar sıfırlanamadı. Lütfen tekrar deneyin.'),
        findsOneWidget,
      );
      expect(resetEventCount, 0);
      verify(
        () => reporter.report(
          any(),
          any(),
          context: 'settings_reset_local_preferences',
        ),
      ).called(1);
    },
  );

  testWidgets('confirmation remains usable at 320dp and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpTile(tester, textScale: 2);

    await openConfirmation(tester);

    expect(find.text('Ayarları Sıfırla'), findsOneWidget);
    expect(find.text('Vazgeç'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
