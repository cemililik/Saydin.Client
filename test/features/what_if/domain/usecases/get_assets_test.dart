import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/network/locale_provider.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';

class _MockRepository extends Mock implements WhatIfRepository {}

class _MutableLocaleProvider implements LocaleProvider {
  _MutableLocaleProvider(this.localeCode);

  @override
  String localeCode;

  @override
  void update(String? languageCode) {
    localeCode = languageCode ?? 'tr';
  }
}

void main() {
  const trAssets = [
    Asset(symbol: 'XAU', displayName: 'Altın', category: 'commodity'),
  ];
  const enAssets = [
    Asset(symbol: 'XAU', displayName: 'Gold', category: 'commodity'),
  ];

  test(
    'four concurrent callers share one request for the same locale',
    () async {
      final repository = _MockRepository();
      final locale = _MutableLocaleProvider('tr');
      final response = Completer<List<Asset>>();
      when(() => repository.getAssets()).thenAnswer((_) => response.future);
      final getAssets = GetAssets(repository, locale);

      final calls = List.generate(4, (_) => getAssets());
      verify(() => repository.getAssets()).called(1);
      response.complete(trAssets);

      final results = await Future.wait(calls);
      expect(results, everyElement(trAssets));
      expect(() => results.first.add(trAssets.first), throwsUnsupportedError);
    },
  );

  test('successful result is cached per locale', () async {
    final repository = _MockRepository();
    final locale = _MutableLocaleProvider('tr');
    when(() => repository.getAssets()).thenAnswer((_) async => trAssets);
    final getAssets = GetAssets(repository, locale);

    expect(await getAssets(), trAssets);
    expect(await getAssets(), trAssets);
    verify(() => repository.getAssets()).called(1);

    locale.update('en');
    when(() => repository.getAssets()).thenAnswer((_) async => enAssets);
    expect(await getAssets(), enAssets);
    expect(await getAssets(), enAssets);
    verify(() => repository.getAssets()).called(1);
  });

  test('failed request is not cached and can be retried', () async {
    final repository = _MockRepository();
    final locale = _MutableLocaleProvider('tr');
    when(
      () => repository.getAssets(),
    ).thenAnswer((_) => Future.error(StateError('offline')));
    final getAssets = GetAssets(repository, locale);

    await expectLater(getAssets(), throwsA(isA<StateError>()));
    when(() => repository.getAssets()).thenAnswer((_) async => trAssets);

    expect(await getAssets(), trAssets);
    verify(() => repository.getAssets()).called(2);
  });

  test('force refresh replaces only the active locale cache', () async {
    final repository = _MockRepository();
    final locale = _MutableLocaleProvider('tr');
    when(() => repository.getAssets()).thenAnswer((_) async => trAssets);
    final getAssets = GetAssets(repository, locale);
    await getAssets();

    const refreshed = [
      Asset(symbol: 'XAU', displayName: 'Gram Altın', category: 'commodity'),
    ];
    when(() => repository.getAssets()).thenAnswer((_) async => refreshed);

    expect(await getAssets(forceRefresh: true), refreshed);
    expect(await getAssets(), refreshed);
    verify(() => repository.getAssets()).called(2);
  });
}
