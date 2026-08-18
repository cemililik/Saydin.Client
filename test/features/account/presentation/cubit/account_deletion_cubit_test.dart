import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/features/account/data/repositories/account_data_repository_impl.dart';
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_cubit.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_state.dart';

class _MockRepository extends Mock implements AccountDataRepository {}

/// Sentry init'i test'te yapılmadığı için reporter çağrıları zaten no-op
/// olur, ancak fake kullanarak (a) mocktail global state sızıntısını
/// engelliyoruz (b) çağrı sayısını tracking için sayıyoruz.
class _FakeErrorReporter implements ErrorReporter {
  final actions = <String>[];
  final reports = <Object>[];
  int scopeClearCount = 0;
  bool throwOnRecordAction = false;
  bool throwOnReport = false;
  int remainingScopeClearFailures = 0;

  @override
  Future<void> recordAction(
    String action, {
    String? category,
    Map<String, Object?>? data,
  }) async {
    if (throwOnRecordAction) throw Exception('telemetry unavailable');
    actions.add(action);
  }

  @override
  Future<void> report(
    Object exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, Object?>? extras,
  }) async {
    if (throwOnReport) throw Exception('reporter unavailable');
    reports.add(exception);
  }

  @override
  Future<void> addBreadcrumb(String message, {String? category}) async {}

  @override
  Future<void> clearScope() async {
    scopeClearCount++;
    if (remainingScopeClearFailures > 0) {
      remainingScopeClearFailures--;
      throw Exception('scope clear unavailable');
    }
  }
}

void main() {
  late _MockRepository repository;
  late _FakeErrorReporter reporter;
  late AppLifecycleEvents lifecycleEvents;
  late int resetCount;

  setUp(() {
    repository = _MockRepository();
    reporter = _FakeErrorReporter();
    lifecycleEvents = AppLifecycleEvents();
    resetCount = 0;
    lifecycleEvents.resetStream.listen((_) => resetCount++);
    when(
      () => repository.hasPendingLocalCleanup(),
    ).thenAnswer((_) async => false);
    when(() => repository.markLocalCleanupPending()).thenAnswer((_) async {});
    when(() => repository.clearPendingLocalCleanup()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await lifecycleEvents.dispose();
  });

  AccountDeletionCubit build() => AccountDeletionCubit(
    repository: repository,
    reporter: reporter,
    lifecycleEvents: lifecycleEvents,
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'happy path: backend OK + wipe başarılı → Success + lifecycle reset event',
    setUp: () {
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionSuccess>(),
    ],
    verify: (_) async {
      verify(() => repository.requestBackendDeletion()).called(1);
      verify(() => repository.markLocalCleanupPending()).called(1);
      verify(() => repository.wipeLocalData()).called(1);
      verify(() => repository.clearPendingLocalCleanup()).called(1);
      expect(reporter.actions, [
        'settings.account_delete_requested',
        'settings.account_deleted',
      ]);
      expect(
        reporter.scopeClearCount,
        1,
        reason: 'Wipe sonrası Sentry scope temizlenmiş olmalı (KVKK Madde 11)',
      );
      expect(reporter.reports, isEmpty);
      // Stream listener async; broadcast'i drain etmek için pump.
      await Future<void>.delayed(Duration.zero);
      expect(resetCount, 1);
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'backend hatası → Failure; local wipe ve device identity korunur',
    setUp: () {
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => false);
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionFailure>().having(
        (state) => state.error,
        'error',
        isA<AccountDeletionBackendException>(),
      ),
    ],
    verify: (_) async {
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => repository.wipeLocalData());
      verifyNever(() => repository.markLocalCleanupPending());
      expect(reporter.scopeClearCount, 0);
      expect(resetCount, 0, reason: 'Local veri korunurken reset olmamalı');
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'wipe başarısızlığı retryable LocalCleanupPending ve Sentry raporu üretir',
    setUp: () {
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(
        () => repository.wipeLocalData(),
      ).thenThrow(AccountWipeException(['io']));
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionLocalCleanupPending>(),
    ],
    verify: (_) async {
      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.first, isA<AccountWipeException>());
      await Future<void>.delayed(Duration.zero);
      expect(resetCount, 0, reason: 'Wipe başarısız → reset event yayılmamalı');
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'remote success sonrası local retry backend DELETE tekrar etmez',
    setUp: () {
      var wipeCalls = 0;
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(() => repository.wipeLocalData()).thenAnswer((_) async {
        wipeCalls++;
        if (wipeCalls == 1) throw AccountWipeException(['temporary io']);
      });
    },
    build: build,
    act: (cubit) async {
      await cubit.requestDeletion();
      await cubit.requestDeletion();
    },
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionLocalCleanupPending>(),
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionSuccess>(),
    ],
    verify: (_) async {
      verify(() => repository.requestBackendDeletion()).called(1);
      verify(() => repository.markLocalCleanupPending()).called(1);
      verify(() => repository.wipeLocalData()).called(2);
      verify(() => repository.clearPendingLocalCleanup()).called(1);
      await Future<void>.delayed(Duration.zero);
      expect(resetCount, 1);
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'marker yazılamazsa wipe başlamaz; retry markerı yazıp cleanupı tamamlar',
    setUp: () {
      var markerWrites = 0;
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(() => repository.markLocalCleanupPending()).thenAnswer((_) async {
        markerWrites++;
        if (markerWrites == 1) throw Exception('disk temporarily read-only');
      });
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      await cubit.requestDeletion();
      await cubit.requestDeletion();
    },
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionLocalCleanupPending>(),
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionSuccess>(),
    ],
    verify: (_) {
      verify(() => repository.requestBackendDeletion()).called(1);
      verify(() => repository.markLocalCleanupPending()).called(2);
      verify(() => repository.wipeLocalData()).called(1);
      verify(() => repository.clearPendingLocalCleanup()).called(1);
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'scope cleanup düşerse marker korunur ve backend tekrar edilmeden retry olur',
    setUp: () {
      reporter.remainingScopeClearFailures = 1;
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) async {
      await cubit.requestDeletion();
      await cubit.requestDeletion();
    },
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionLocalCleanupPending>(),
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionSuccess>(),
    ],
    verify: (_) {
      verify(() => repository.requestBackendDeletion()).called(1);
      verify(() => repository.wipeLocalData()).called(2);
      verify(() => repository.clearPendingLocalCleanup()).called(1);
      expect(reporter.scopeClearCount, 2);
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'telemetry hatası başarılı silme sonucunu veya reseti engellemez',
    setUp: () {
      reporter.throwOnRecordAction = true;
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionSuccess>(),
    ],
    verify: (_) async {
      await Future<void>.delayed(Duration.zero);
      expect(resetCount, 1);
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'reporter da hata atsa cleanup failure terminal state üretir',
    setUp: () {
      reporter.throwOnReport = true;
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(
        () => repository.wipeLocalData(),
      ).thenThrow(AccountWipeException(['io']));
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionLocalCleanupPending>(),
    ],
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'persisted pending marker app restart sonrası yalnız local cleanup sürdürür',
    setUp: () {
      when(
        () => repository.hasPendingLocalCleanup(),
      ).thenAnswer((_) async => true);
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionSuccess>(),
    ],
    verify: (_) {
      verifyNever(() => repository.requestBackendDeletion());
      verifyNever(() => repository.markLocalCleanupPending());
      verify(() => repository.wipeLocalData()).called(1);
      verify(() => repository.clearPendingLocalCleanup()).called(1);
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'InProgress sırasında ikinci tetikleme ignore edilir',
    build: build,
    seed: () => const AccountDeletionInProgress(),
    act: (cubit) => cubit.requestDeletion(),
    expect: () => const <AccountDeletionState>[],
    verify: (_) {
      verifyNever(() => repository.requestBackendDeletion());
      verifyNever(() => repository.wipeLocalData());
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'requestBackendDeletion beklenmedik şekilde throw ederse local wipe çalışmaz',
    setUp: () {
      // Repository sözleşmesi throw etmemeyi söylüyor; cubit yine de
      // defansif olmalı. Burada implementation'ın sözleşmeyi ihlal ettiği
      // bir durumu simüle ediyoruz.
      when(
        () => repository.requestBackendDeletion(),
      ).thenThrow(Exception('unexpected'));
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionFailure>(),
    ],
    verify: (_) async {
      verifyNever(() => repository.wipeLocalData());
      // Beklenmedik backend exception raporlanır.
      expect(
        reporter.reports.length,
        1,
        reason: 'Sadece beklenmedik backend exception raporlanır',
      );
      await Future<void>.delayed(Duration.zero);
      expect(resetCount, 0);
    },
  );
}
