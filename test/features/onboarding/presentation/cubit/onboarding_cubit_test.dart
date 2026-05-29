import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:saydin/features/onboarding/presentation/cubit/onboarding_cubit.dart';

class _MockRepository extends Mock implements OnboardingRepository {}

class _MockErrorReporter extends Mock implements ErrorReporter {}

/// F-12-09: onboarding durumu ad-hoc `bool? + setState`'ten cubit'e taşındı.
/// Bu testler taşınan yaşam-döngüsü mantığını kapsar: load/complete/restart,
/// hesap-silme reset aboneliği ve `close()`'ta aboneliğin iptali.
void main() {
  late _MockRepository repository;
  late AppLifecycleEvents lifecycleEvents;
  late _MockErrorReporter reporter;

  setUpAll(() => registerFallbackValue(StackTrace.empty));

  setUp(() {
    repository = _MockRepository();
    lifecycleEvents = AppLifecycleEvents();
    reporter = _MockErrorReporter();
    when(
      () => reporter.report(any(), any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await lifecycleEvents.dispose();
  });

  OnboardingCubit build() => OnboardingCubit(repository, lifecycleEvents);

  test('initialState_isUnknown', () {
    expect(build().state, OnboardingStatus.unknown);
  });

  group('load', () {
    blocTest<OnboardingCubit, OnboardingStatus>(
      'load_completed_emitsCompleted',
      setUp: () => when(
        () => repository.isOnboardingCompleted(),
      ).thenAnswer((_) async => true),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [OnboardingStatus.completed],
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
    build: () =>
        OnboardingCubit(repository, lifecycleEvents, reporter: reporter),
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

  blocTest<OnboardingCubit, OnboardingStatus>(
    'resetStreamEvent_triggersRestart_reloadsFromRepo',
    setUp: () => when(
      () => repository.isOnboardingCompleted(),
    ).thenAnswer((_) async => true),
    build: build,
    // restart() önce unknown emit eder (ilk emit bloc'ta initial state'e eşit
    // olsa da geçer), sonra load() repodan okuyup completed yayar.
    act: (cubit) => lifecycleEvents.requestReset(),
    wait: const Duration(milliseconds: 1),
    expect: () => [OnboardingStatus.unknown, OnboardingStatus.completed],
    verify: (_) => verify(() => repository.isOnboardingCompleted()).called(1),
  );

  test('close_cancelsResetSubscription_noRestartAfterClose', () async {
    when(
      () => repository.isOnboardingCompleted(),
    ).thenAnswer((_) async => false);
    final cubit = build();

    await cubit.close();
    lifecycleEvents.requestReset();
    await Future<void>.delayed(Duration.zero);

    // Abonelik iptal edildiyse reset event restart()'ı (→ repo okuması)
    // tetiklemez; aksi halde close sonrası emit StateError atardı.
    verifyNever(() => repository.isOnboardingCompleted());
  });
}
