import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/constants/app_branding.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/theme/app_theme.dart';
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

  /// [surfaceSize] gerçek `RenderView` yüzeyini değiştirir. Yalnız
  /// `MediaQuery` override etmek yeterli değildir: kök constraint'ler
  /// varsayılan 800x600 yüzeyden gelir, dolayısıyla dar ekran yerleşimi
  /// hiç sınanmamış olur.
  Future<void> pumpPage(
    WidgetTester tester, {
    required VoidCallback onComplete,
    bool legalUpdateOnly = false,
    Size? surfaceSize,
    TextScaler? textScaler,
    bool disableAnimations = false,
    Brightness brightness = Brightness.light,
  }) async {
    if (surfaceSize != null) {
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    final page = OnboardingPage(
      onComplete: onComplete,
      legalUpdateOnly: legalUpdateOnly,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: textScaler,
              disableAnimations: disableAnimations ? true : null,
            ),
            child: page,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// CTA'ya basarak bir sonraki sayfaya geçer. `jumpToPage` butonun kendi
  /// ilerletme dalını atladığı için akış testlerinde kullanılmaz.
  Future<void> tapPrimaryAction(WidgetTester tester) async {
    final action = find.byKey(const Key('onboarding-primary-action'));
    await tester.ensureVisible(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
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

      expect(find.text('Bir sorudan fazlası.'), findsOneWidget);
      expect(find.text('Yasal metinler güncellendi'), findsNothing);
      verifyNever(() => onboardingRepository.recordLegalNotice(any()));
    },
  );

  testWidgets('walks the three-page flow with the primary action', (
    tester,
  ) async {
    var completedCount = 0;
    await pumpPage(tester, onComplete: () => completedCount++);

    final brandLogo = tester.widget<Image>(
      find.byKey(const Key('onboarding-brand-logo')),
    );
    expect(
      (brandLogo.image as AssetImage).assetName,
      AppBranding.horizontalLogoOnLightAsset,
    );
    expect(find.byKey(const Key('onboarding-brand-symbol')), findsOneWidget);
    expect(find.text('Ya alsaydım, artık merak değil.'), findsOneWidget);
    expect(find.bySemanticsLabel('3 sayfadan 1. sayfa'), findsOneWidget);
    expect(find.text('İleri'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-brand-visual')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-toolkit-visual')), findsNothing);
    expect(find.byKey(const Key('onboarding-result-visual')), findsNothing);

    final pageView = tester.widget<PageView>(
      find.byKey(const Key('onboarding-page-view')),
    );
    expect(pageView.controller?.initialPage, 0);

    await tapPrimaryAction(tester);

    expect(find.text('Bir sorudan fazlası.'), findsOneWidget);
    expect(find.bySemanticsLabel('3 sayfadan 2. sayfa'), findsOneWidget);
    expect(find.text('İleri'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-toolkit-visual')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-brand-visual')), findsNothing);
    expect(completedCount, 0);

    await tapPrimaryAction(tester);

    expect(find.text('Merakınızı rakama dönüştürün.'), findsOneWidget);
    expect(find.bySemanticsLabel('3 sayfadan 3. sayfa'), findsOneWidget);
    expect(find.text('Hemen Dene'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-result-visual')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-toolkit-visual')), findsNothing);
    expect(completedCount, 0);
    verifyNever(() => onboardingRepository.recordLegalNotice(any()));

    await tapPrimaryAction(tester);

    expect(completedCount, 1);
    verify(() => onboardingRepository.recordLegalNotice(any())).called(1);
  });

  testWidgets('uses the dark lockup when the app runs in dark theme', (
    tester,
  ) async {
    await pumpPage(tester, onComplete: () {}, brightness: Brightness.dark);

    final brandLogo = tester.widget<Image>(
      find.byKey(const Key('onboarding-brand-logo')),
    );
    expect(
      (brandLogo.image as AssetImage).assetName,
      AppBranding.horizontalLogoOnDarkAsset,
    );
  });

  testWidgets('legal update screen keeps the neutral document visual', (
    tester,
  ) async {
    await pumpPage(tester, onComplete: () {}, legalUpdateOnly: true);

    expect(
      find.byKey(const Key('onboarding-legal-update-visual')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('onboarding-result-visual')), findsNothing);
  });

  testWidgets('legal document links keep a 48dp tap target', (tester) async {
    await pumpPage(tester, onComplete: () {});

    for (final key in const [
      Key('onboarding-privacy-link'),
      Key('onboarding-kvkk-link'),
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.height, greaterThanOrEqualTo(48.0), reason: '$key height');
      expect(size.width, greaterThanOrEqualTo(48.0), reason: '$key width');
    }

    final privacy = tester.getRect(
      find.byKey(const Key('onboarding-privacy-link')),
    );
    final kvkk = tester.getRect(find.byKey(const Key('onboarding-kvkk-link')));
    expect(privacy.overlaps(kvkk), isFalse);
  });

  testWidgets('result illustration paints a chart with real height', (
    tester,
  ) async {
    await pumpPage(tester, onComplete: () {});
    await tapPrimaryAction(tester);
    await tapPrimaryAction(tester);

    final chart = tester.getSize(
      find.byKey(const Key('onboarding-result-chart')),
    );
    expect(chart.height, greaterThan(40));
    expect(chart.width, greaterThan(40));
  });

  testWidgets('toolkit badge stays centred on the grid on a tall viewport', (
    tester,
  ) async {
    await pumpPage(
      tester,
      onComplete: () {},
      surfaceSize: const Size(390, 844),
    );
    await tapPrimaryAction(tester);

    final grid = tester.getRect(
      find.byKey(const Key('onboarding-toolkit-visual')),
    );
    final badge = tester.getRect(
      find.byKey(const Key('onboarding-toolkit-badge')),
    );
    expect(badge.center.dy, closeTo(grid.center.dy, 1));
    // shrinkWrap olmasaydı grid tüm slotu kaplardı.
    final slot = tester.getSize(find.byKey(const Key('onboarding-page-view')));
    expect(grid.height, lessThan(slot.height));
  });

  testWidgets('feature tile labels keep usable width at 360dp', (tester) async {
    await pumpPage(
      tester,
      onComplete: () {},
      surfaceSize: const Size(360, 800),
      textScaler: const TextScaler.linear(1.25),
    );
    await tapPrimaryAction(tester);

    expect(
      tester.getSize(find.text('Karşılaştır')).width,
      greaterThanOrEqualTo(96.0),
    );
  });

  testWidgets('main flow survives 320dp at 200% text', (tester) async {
    await pumpPage(
      tester,
      onComplete: () {},
      surfaceSize: const Size(320, 480),
      textScaler: const TextScaler.linear(2),
      disableAnimations: true,
    );

    expect(tester.takeException(), isNull);
    await tapPrimaryAction(tester);
    expect(tester.takeException(), isNull);
    await tapPrimaryAction(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Hemen Dene'), findsOneWidget);
  });

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
      surfaceSize: const Size(320, 480),
      textScaler: const TextScaler.linear(2),
      disableAnimations: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(find.text('Devam Et'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
