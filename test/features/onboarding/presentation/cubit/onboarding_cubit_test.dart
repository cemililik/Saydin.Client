import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:saydin/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class _MockRepository extends Mock implements OnboardingRepository {}

class _MockErrorReporter extends Mock implements ErrorReporter {}

/// F-12-09: onboarding durumu ad-hoc `bool? + setState`'ten cubit'e taşındı.
/// Bu testler taşınan yaşam-döngüsü mantığını kapsar: load/complete/restart.
/// Hesap-silme session reset sahipliği app-level boundary testindedir.
void main() {
  late _MockRepository repository;
  late _MockErrorReporter reporter;

  setUpAll(() => registerFallbackValue(StackTrace.empty));

  setUp(() {
    repository = _MockRepository();
    reporter = _MockErrorReporter();
    when(
      () => reporter.report(any(), any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
  });

  OnboardingCubit build() => OnboardingCubit(repository);
  final currentLegalNotice = LegalNoticeRecord.current(
    locale: 'tr-TR',
    recordedAtUtc: DateTime.utc(2026, 8, 18),
    decision: LegalNoticeDecision.acknowledged,
  );

  test('initialState_isUnknown', () {
    expect(build().state, OnboardingStatus.unknown);
  });

  group('load', () {
    blocTest<OnboardingCubit, OnboardingStatus>(
      'load_completed_emitsCompleted',
      setUp: () => when(
        () => repository.isOnboardingCompleted(),
      ).thenAnswer((_) async => true),
      build: () {
        when(
          () => repository.getLegalNotice(),
        ).thenAnswer((_) async => currentLegalNotice);
        return OnboardingCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [OnboardingStatus.completed],
    );

    blocTest<OnboardingCubit, OnboardingStatus>(
      'load_completedButOldLegalNotice_requiresUpdate',
      setUp: () => when(
        () => repository.isOnboardingCompleted(),
      ).thenAnswer((_) async => true),
      build: () {
        when(() => repository.getLegalNotice()).thenAnswer(
          (_) async => LegalNoticeRecord(
            version: LegalAcceptanceVersion.current - 1,
            bundleSha256:
                '0000000000000000000000000000000000000000000000000000000000000000',
            privacyDocumentId: 'privacy-v1',
            kvkkDocumentId: 'kvkk-v1',
            locale: 'tr-TR',
            recordedAtUtc: DateTime.utc(2026, 1, 1),
            decision: LegalNoticeDecision.acknowledged,
          ),
        );
        return OnboardingCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [OnboardingStatus.legalUpdateRequired],
    );

    blocTest<OnboardingCubit, OnboardingStatus>(
      'load_completedWithoutLegalNotice_requiresOneTimeUpdate',
      setUp: () => when(
        () => repository.isOnboardingCompleted(),
      ).thenAnswer((_) async => true),
      build: () {
        when(() => repository.getLegalNotice()).thenAnswer((_) async => null);
        return OnboardingCubit(repository);
      },
      act: (cubit) => cubit.load(),
      expect: () => [OnboardingStatus.legalUpdateRequired],
    );

    blocTest<OnboardingCubit, OnboardingStatus>(
      'load_notCompleted_emitsPending',
      setUp: () => when(
        () => repository.isOnboardingCompleted(),
      ).thenAnswer((_) async => false),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [OnboardingStatus.pending],
    );
  });

  blocTest<OnboardingCubit, OnboardingStatus>(
    'complete_persistsAndEmitsCompleted',
    setUp: () =>
        when(() => repository.completeOnboarding()).thenAnswer((_) async {}),
    build: build,
    act: (cubit) => cubit.complete(),
    expect: () => [OnboardingStatus.completed],
    verify: (_) => verify(() => repository.completeOnboarding()).called(1),
  );

  // F-12-18 / F-05-28: kalıcı kayıt çökse bile kullanıcı içeri girebilmeli
  // (completed emit edilir) ve hata raporlanmalı — kullanıcı onboarding'te
  // kilitlenmez.
  blocTest<OnboardingCubit, OnboardingStatus>(
    'complete_storageFails_stillEmitsCompleted_andReports',
    setUp: () => when(
      () => repository.completeOnboarding(),
    ).thenThrow(Exception('disk full')),
    build: () => OnboardingCubit(repository, reporter: reporter),
    act: (cubit) => cubit.complete(),
    expect: () => [OnboardingStatus.completed],
    verify: (_) => verify(
      () => reporter.report(any(), any(), context: 'onboarding_complete'),
    ).called(1),
  );

  blocTest<OnboardingCubit, OnboardingStatus>(
    'restart_emitsUnknownThenRereadsFromRepo',
    setUp: () => when(
      () => repository.isOnboardingCompleted(),
    ).thenAnswer((_) async => false),
    build: build,
    seed: () => OnboardingStatus.completed,
    act: (cubit) => cubit.restart(),
    expect: () => [OnboardingStatus.unknown, OnboardingStatus.pending],
  );
}
