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

  @override
  Future<void> recordAction(
    String action, {
    String? category,
    Map<String, Object?>? data,
  }) async {
    actions.add(action);
  }

  @override
  Future<void> report(
    Object exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, Object?>? extras,
  }) async {
    reports.add(exception);
  }

  @override
  Future<void> addBreadcrumb(String message, {String? category}) async {}
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
      verify(() => repository.wipeLocalData()).called(1);
      expect(reporter.actions, [
        'settings.account_delete_requested',
        'settings.account_deleted',
      ]);
      expect(reporter.reports, isEmpty);
      // Stream listener async; broadcast'i drain etmek için pump.
      await Future<void>.delayed(Duration.zero);
      expect(resetCount, 1);
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'backend hatası + yerel wipe başarılı → PartialSuccess (Success değil)',
    setUp: () {
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => false);
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionPartialSuccess>(),
    ],
    verify: (_) async {
      await Future<void>.delayed(Duration.zero);
      expect(
        resetCount,
        1,
        reason: 'Yerel veri silindi → reset event yine de yayılmalı',
      );
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'wipe başarısızlığı Failure state ve Sentry raporu üretir',
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
      isA<AccountDeletionFailure>(),
    ],
    verify: (_) async {
      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.first, isA<AccountWipeException>());
      await Future<void>.delayed(Duration.zero);
      expect(resetCount, 0, reason: 'Wipe başarısız → reset event yayılmamalı');
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
    'requestBackendDeletion BEKLENMEDİK ŞEKİLDE throw etse de yerel wipe çalışır',
    setUp: () {
      // Repository sözleşmesi throw etmemeyi söylüyor; cubit yine de
      // defansif olmalı. Burada implementation'ın sözleşmeyi ihlal ettiği
      // bir durumu simüle ediyoruz.
      when(
        () => repository.requestBackendDeletion(),
      ).thenThrow(Exception('unexpected'));
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: build,
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      // backendOk = false (exception sonrası); yerel wipe başarılı → Partial
      isA<AccountDeletionPartialSuccess>(),
    ],
    verify: (_) async {
      verify(() => repository.wipeLocalData()).called(1);
      // Hem backend exception hem account_deletion context'leri raporlanır
      expect(
        reporter.reports.length,
        1,
        reason: 'Sadece beklenmedik backend exception raporlanır',
      );
      await Future<void>.delayed(Duration.zero);
      expect(resetCount, 1);
    },
  );
}
