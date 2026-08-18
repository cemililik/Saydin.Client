import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_cubit.dart';
import 'package:saydin/features/account/presentation/pages/delete_account_page.dart';
import 'package:saydin/l10n/app_localizations.dart';

class _MockAccountDataRepository extends Mock
    implements AccountDataRepository {}

class _NoOpErrorReporter implements ErrorReporter {
  @override
  Future<void> addBreadcrumb(String message, {String? category}) async {}

  @override
  Future<void> clearScope() async {}

  @override
  Future<void> recordAction(
    String action, {
    String? category,
    Map<String, Object?>? data,
  }) async {}

  @override
  Future<void> report(
    Object exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, Object?>? extras,
  }) async {}
}

void main() {
  late AppLifecycleEvents lifecycleEvents;

  setUp(() async {
    await sl.reset();
    lifecycleEvents = AppLifecycleEvents();
    sl.registerSingleton<AccountDeletionCubit>(
      AccountDeletionCubit(
        repository: _MockAccountDataRepository(),
        reporter: _NoOpErrorReporter(),
        lifecycleEvents: lifecycleEvents,
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
    await lifecycleEvents.dispose();
  });

  testWidgets(
    'remains scrollable at 320dp, 200% text and with keyboard inset',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 480),
              textScaler: TextScaler.linear(2),
              viewInsets: EdgeInsets.only(bottom: 220),
            ),
            child: DeleteAccountPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final confirmButton = find.text('Permanently Delete My Account');
      await tester.ensureVisible(confirmButton);
      await tester.pumpAndSettle();

      expect(confirmButton, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
