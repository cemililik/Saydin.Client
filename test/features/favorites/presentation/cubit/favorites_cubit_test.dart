import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:saydin/features/favorites/presentation/cubit/favorites_cubit.dart';

class _MockRepository extends Mock implements FavoritesRepository {}

class _MockErrorReporter extends Mock implements ErrorReporter {}

void main() {
  late _MockRepository repo;
  late _MockErrorReporter reporter;

  setUpAll(() {
    registerFallbackValue(<String>{});
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    repo = _MockRepository();
    reporter = _MockErrorReporter();
    when(() => repo.load()).thenAnswer((_) async => <String>{});
    when(() => repo.save(any())).thenAnswer((_) async {});
    when(
      () => reporter.report(any(), any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
  });

  FavoritesCubit build() => FavoritesCubit(repo, reporter: reporter);

  blocTest<FavoritesCubit, Set<String>>(
    'load_repositoryReturnsFavorites_emitsFavorites',
    setUp: () =>
        when(() => repo.load()).thenAnswer((_) async => {'USDTRY', 'BTC'}),
    build: build,
    act: (c) => c.load(),
    expect: () => [
      {'USDTRY', 'BTC'},
    ],
  );

  blocTest<FavoritesCubit, Set<String>>(
    'toggle_addsFavorite_emitsAndSaves',
    build: build,
    act: (c) => c.toggle('BTC'),
    expect: () => [
      {'BTC'},
    ],
    verify: (_) => verify(() => repo.save({'BTC'})).called(1),
  );

  blocTest<FavoritesCubit, Set<String>>(
    'toggle_atMaxCount_doesNotAddOrSave',
    seed: () => {'A', 'B', 'C', 'D', 'E'},
    build: build,
    act: (c) => c.toggle('F'),
    expect: () => <Set<String>>[],
    verify: (_) => verifyNever(() => repo.save(any())),
  );

  // F-11-10: kalıcı yazma başarısızsa optimistic değişiklik geri alınır
  // (rollback) ve hata raporlanır — sessizce yutulmaz.
  blocTest<FavoritesCubit, Set<String>>(
    'toggle_saveFails_rollsBackAndReports',
    setUp: () => when(() => repo.save(any())).thenThrow(Exception('disk full')),
    build: build,
    act: (c) => c.toggle('BTC'),
    expect: () => [
      {'BTC'}, // optimistic
      <String>{}, // rollback
    ],
    verify: (_) {
      verify(
        () => reporter.report(any(), any(), context: 'favorites_toggle'),
      ).called(1);
    },
  );

  // Yarış koruması: ilk toggle'ın save'i beklerken araya ikinci (başarılı)
  // toggle girer; ilkinin save'i SONRA başarısız olur. Stale `previous`'a
  // rollback, ikinci toggle'ın sonucunu EZMEMELİ (identical guard).
  test('toggle_saveFailsAfterInterveningToggle_doesNotClobber', () async {
    final firstSave = Completer<void>();
    var calls = 0;
    when(() => repo.save(any())).thenAnswer((_) {
      calls++;
      return calls == 1 ? firstSave.future : Future<void>.value();
    });
    final cubit = build();

    final toggleA = cubit.toggle('BTC'); // emit {BTC}, save gated (fail edecek)
    await cubit.toggle('ETH'); // emit {BTC,ETH}, save başarılı
    expect(cubit.state, {'BTC', 'ETH'});

    firstSave.completeError(Exception('disk full')); // A'nın save'i başarısız
    await toggleA;

    // A'nın rollback'i {BTC,ETH}'i EZMEDİ (araya emit girdiği için atlandı).
    expect(cubit.state, {'BTC', 'ETH'});
    verify(
      () => reporter.report(any(), any(), context: 'favorites_toggle'),
    ).called(1);

    await cubit.close();
  });
}
