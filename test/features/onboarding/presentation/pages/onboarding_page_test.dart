import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/legal/domain/repositories/legal_repository.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:saydin/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:saydin/l10n/app_localizations.dart';

class _MockOnboardingRepository extends Mock implements OnboardingRepository {}

class _MockLegalRepository extends Mock implements LegalRepository {}

class _MockErrorReporter extends Mock implements ErrorReporter {}

void main() {
  late _MockOnboardingRepository onboardingRepository;
  late _MockErrorReporter errorReporter;

  setUpAll(() {
    registerFallbackValue(
      LegalNoticeRecord.current(
        locale: 'tr-TR',
        recordedAtUtc: DateTime.utc(2026, 8, 18),
        decision: LegalNoticeDecision.seen,
      ),
    );
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() async {
    await sl.reset();
    onboardingRepository = _MockOnboardingRepository();
    errorReporter = _MockErrorReporter();
    sl.registerSingleton<OnboardingRepository>(onboardingRepository);
    sl.registerSingleton<LegalRepository>(_MockLegalRepository());
    sl.registerSingleton<ErrorReporter>(errorReporter);
    when(
      () => onboardingRepository.recordLegalNotice(any()),
    ).thenAnswer((_) async {});
    when(
      () => errorReporter.report(any(), any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required VoidCallback onComplete,
    bool legalUpdateOnly = false,
    MediaQueryData? mediaQueryData,
  }) async {
    final page = OnboardingPage(
      onComplete: onComplete,
      legalUpdateOnly: legalUpdateOnly,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: mediaQueryData == null
            ? page
            : MediaQuery(data: mediaQueryData, child: page),
      ),
    );
    await tester.pump();
  }

  testWidgets('skip records visible legal notice as seen, not acceptance', (
    tester,
  ) async {
    var completedCount = 0;
    await pumpPage(tester, onComplete: () => completedCount++);

    await tester.tap(find.text('Atla'));
    await tester.pump();

    expect(completedCount, 1);
    final record =
        verify(
              () => onboardingRepository.recordLegalNotice(captureAny()),
            ).captured.single
            as LegalNoticeRecord;
    expect(record.decision, LegalNoticeDecision.seen);
    expect(record.isCurrent, isTrue);
    expect(find.byKey(const Key('onboarding-privacy-link')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-kvkk-link')), findsOneWidget);
  });

  testWidgets('legal update later records seen, not acknowledged', (
    tester,
  ) async {
    var completedCount = 0;
    await pumpPage(
      tester,
      onComplete: () => completedCount++,
      legalUpdateOnly: true,
    );

    await tester.tap(find.text('Atla'));
    await tester.pump();

    final record =
        verify(
              () => onboardingRepository.recordLegalNotice(captureAny()),
            ).captured.single
            as LegalNoticeRecord;
    expect(record.decision, LegalNoticeDecision.seen);
    expect(record.isCurrent, isTrue);
    expect(record.locale, startsWith('tr'));
    expect(completedCount, 1);
  });

  testWidgets(
    'legal update starts with clear notice and allows previous pages',
    (tester) async {
      await pumpPage(tester, onComplete: () {}, legalUpdateOnly: true);

      expect(find.text('Yasal metinler güncellendi'), findsOneWidget);
      expect(find.text('Devam Et'), findsOneWidget);
      expect(find.byKey(const Key('onboarding-back')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding-back')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Ters Senaryo'), findsOneWidget);
      expect(find.text('Yasal metinler güncellendi'), findsNothing);
      verifyNever(() => onboardingRepository.recordLegalNotice(any()));
    },
  );

  testWidgets('continues without a checkbox and records only seen', (
    tester,
  ) async {
    var completedCount = 0;
    await pumpPage(
      tester,
      onComplete: () => completedCount++,
      legalUpdateOnly: true,
    );

    expect(find.byType(Checkbox), findsNothing);
    expect(
      find.byKey(const Key('onboarding-legal-notice-statement')),
      findsOneWidget,
    );
    final cta = find.text('Devam Et');
    final ctaButton = find.ancestor(of: cta, matching: find.byType(InkWell));
    expect(ctaButton, findsOneWidget);
    await tester.ensureVisible(ctaButton);
    await tester.pump();
    expect(ctaButton.hitTestable(), findsOneWidget);
    await tester.tap(ctaButton.hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final record =
        verify(
              () => onboardingRepository.recordLegalNotice(captureAny()),
            ).captured.single
            as LegalNoticeRecord;
    expect(record.decision, LegalNoticeDecision.seen);
    expect(completedCount, 1);
  });

  testWidgets('legal record failure is visible and retryable', (tester) async {
    when(
      () => onboardingRepository.recordLegalNotice(any()),
    ).thenThrow(Exception('disk full'));
    var completedCount = 0;
    await pumpPage(
      tester,
      onComplete: () => completedCount++,
      legalUpdateOnly: true,
    );

    await tester.tap(find.text('Atla'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(completedCount, 0);
    final errorText = find.text(
      'Legal bilgilendirme kaydı kaydedilemedi. Lütfen tekrar deneyin.',
    );
    await tester.ensureVisible(errorText);
    expect(errorText, findsOneWidget);
    verify(
      () => errorReporter.report(
        any(),
        any(),
        context: 'legal_notice_save_failed',
      ),
    ).called(1);

    when(
      () => onboardingRepository.recordLegalNotice(any()),
    ).thenAnswer((_) async {});
    final skip = find.text('Atla');
    await tester.ensureVisible(skip);
    await tester.pump();
    await tester.tap(skip);
    await tester.pump();
    expect(completedCount, 1);
  });

  testWidgets('legal page scrolls at 320dp and 200% text without overflow', (
    tester,
  ) async {
    await pumpPage(
      tester,
      onComplete: () {},
      legalUpdateOnly: true,
      mediaQueryData: const MediaQueryData(
        size: Size(320, 480),
        textScaler: TextScaler.linear(2),
        disableAnimations: true,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(find.text('Devam Et'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
