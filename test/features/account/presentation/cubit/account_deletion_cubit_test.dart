import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/error_reporter.dart';
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

  setUp(() {
    repository = _MockRepository();
    reporter = _FakeErrorReporter();
  });

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'happy path: backend OK + wipe başarılı → InProgress, Success',
    setUp: () {
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: () =>
        AccountDeletionCubit(repository: repository, reporter: reporter),
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionSuccess>(),
    ],
    verify: (_) {
      verify(() => repository.requestBackendDeletion()).called(1);
      verify(() => repository.wipeLocalData()).called(1);
      expect(reporter.actions, [
        'settings.account_delete_requested',
        'settings.account_deleted',
      ]);
      expect(reporter.reports, isEmpty);
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'backend hatası verse bile yerel wipe başarılıysa Success emit edilir',
    setUp: () {
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => false);
      when(() => repository.wipeLocalData()).thenAnswer((_) async {});
    },
    build: () =>
        AccountDeletionCubit(repository: repository, reporter: reporter),
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionSuccess>(),
    ],
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'wipe başarısızlığı Failure state\'i ve Sentry raporu üretir',
    setUp: () {
      when(
        () => repository.requestBackendDeletion(),
      ).thenAnswer((_) async => true);
      when(
        () => repository.wipeLocalData(),
      ).thenThrow(AccountWipeException(['io']));
    },
    build: () =>
        AccountDeletionCubit(repository: repository, reporter: reporter),
    act: (cubit) => cubit.requestDeletion(),
    expect: () => [
      isA<AccountDeletionInProgress>(),
      isA<AccountDeletionFailure>(),
    ],
    verify: (_) {
      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.first, isA<AccountWipeException>());
    },
  );

  blocTest<AccountDeletionCubit, AccountDeletionState>(
    'InProgress sırasında ikinci tetikleme ignore edilir',
    build: () =>
        AccountDeletionCubit(repository: repository, reporter: reporter),
    seed: () => const AccountDeletionInProgress(),
    act: (cubit) => cubit.requestDeletion(),
    expect: () => const <AccountDeletionState>[],
    verify: (_) {
      verifyNever(() => repository.requestBackendDeletion());
      verifyNever(() => repository.wipeLocalData());
    },
  );
}
