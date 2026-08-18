import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_event.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_state.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

class MockGetAssets extends Mock implements GetAssets {}

class MockCompareWhatIf extends Mock implements CompareWhatIf {}

void main() {
  late MockGetAssets getAssets;
  late MockCompareWhatIf compare;

  setUp(() {
    getAssets = MockGetAssets();
    compare = MockCompareWhatIf();
  });

  ComparisonBloc build() => ComparisonBloc(getAssets, compare);

  Asset asset(String symbol, DateTime first, DateTime last) => Asset(
    symbol: symbol,
    displayName: symbol,
    category: 'test',
    firstDate: first,
    lastDate: last,
  );

  CompareResult result() => CompareResult(
    results: [
      CompareResultItem(
        rank: 1,
        calculation: WhatIfResult(
          assetSymbol: 'A',
          assetDisplayName: 'A',
          buyDate: DateTime(2021),
          buyPrice: Decimal.one,
          sellPrice: Decimal.fromInt(2),
          unitsAcquired: Decimal.one,
          initialValueTry: Decimal.one,
          finalValueTry: Decimal.fromInt(2),
          profitLossTry: Decimal.one,
          profitLossPercent: 100,
          isProfit: true,
        ),
      ),
    ],
  );

  group('ComparisonBloc — F-10-02 buyDate null guard', () {
    // Eski kod loaded.buyDate! ile crash ederdi; guard hiçbir state emit
    // etmeden döner. expect [] hem crash hem yanlış emit'i yakalar.
    blocTest<ComparisonBloc, ComparisonState>(
      'onCalculateRequested_buyDateNull_noEmitNoCrash',
      build: build,
      seed: () => ComparisonAssetsLoaded(
        assets: const [],
        selectedSymbols: const ['USDTRY', 'BTC'],
        amount: Decimal.fromInt(1000),
        // buyDate null
      ),
      act: (b) => b.add(const ComparisonCalculateRequested()),
      expect: () => const <ComparisonState>[],
    );

    blocTest<ComparisonBloc, ComparisonState>(
      'onCalculateRequested_amountNull_noEmitNoCrash',
      build: build,
      seed: () => ComparisonAssetsLoaded(
        assets: const [],
        selectedSymbols: const ['USDTRY', 'BTC'],
        buyDate: DateTime.utc(2021, 1, 1),
        // amount null
      ),
      act: (b) => b.add(const ComparisonCalculateRequested()),
      expect: () => const <ComparisonState>[],
    );
  });

  group('ComparisonBloc — tarih ve locale invariantları', () {
    blocTest<ComparisonBloc, ComparisonState>(
      'örtüşmesiz sembol eklendiğinde eski tarihleri atomik temizler',
      build: build,
      seed: () => ComparisonAssetsLoaded(
        assets: [
          asset('A', DateTime(2020), DateTime(2021)),
          asset('B', DateTime(2022), DateTime(2023)),
        ],
        selectedSymbols: const ['A'],
        buyDate: DateTime(2020, 6),
        sellDate: DateTime(2020, 12),
      ),
      act: (bloc) => bloc.add(const ComparisonSymbolToggled('B')),
      expect: () => [
        isA<ComparisonAssetsLoaded>()
            .having((s) => s.selectedSymbols, 'symbols', ['A', 'B'])
            .having((s) => s.buyDate, 'buyDate', isNull)
            .having((s) => s.sellDate, 'sellDate', isNull),
      ],
    );

    blocTest<ComparisonBloc, ComparisonState>(
      'dil değişimi sonucu korur ve comparison hesabını çağırmaz',
      build: build,
      setUp: () => when(() => getAssets()).thenAnswer(
        (_) async => [
          Asset(
            symbol: 'A',
            displayName: 'Localized A',
            category: 'test',
            firstDate: DateTime(2020),
            lastDate: DateTime(2023),
          ),
        ],
      ),
      seed: () => ComparisonSuccess(
        assets: [asset('A', DateTime(2020), DateTime(2023))],
        selectedSymbols: const ['A', 'B'],
        buyDate: DateTime(2021),
        amount: Decimal.fromInt(100),
        result: result(),
      ),
      act: (bloc) => bloc.add(const ComparisonLanguageChanged()),
      expect: () => [
        isA<ComparisonSuccess>()
            .having(
              (s) => s.result.results.single.calculation.finalValueTry,
              'financial result',
              Decimal.fromInt(2),
            )
            .having(
              (s) => s.result.results.single.calculation.assetDisplayName,
              'localized result name',
              'Localized A',
            ),
      ],
      verify: (_) => verifyZeroInteractions(compare),
    );

    blocTest<ComparisonBloc, ComparisonState>(
      'başarılı sonuçta tutar temizlenince eski sonuç geçersiz olur',
      build: build,
      seed: () => ComparisonSuccess(
        assets: [asset('A', DateTime(2020), DateTime(2023))],
        selectedSymbols: const ['A', 'B'],
        buyDate: DateTime(2021),
        amount: Decimal.fromInt(100),
        result: result(),
      ),
      act: (bloc) => bloc.add(const ComparisonAmountChanged(null)),
      expect: () => [
        isA<ComparisonAssetsLoaded>().having(
          (state) => state.amount,
          'amount',
          isNull,
        ),
      ],
    );
  });

  blocTest<ComparisonBloc, ComparisonState>(
    'replay bilinmeyen sembol veya 2 altı seçimle hesaplamayı atlayamaz',
    build: build,
    seed: () => ComparisonAssetsLoaded(
      assets: [
        asset('A', DateTime(2020), DateTime(2023)),
        asset('B', DateTime(2020), DateTime(2023)),
      ],
    ),
    act: (bloc) => bloc.add(
      ComparisonReplayRequested(
        symbols: const ['UNKNOWN'],
        buyDate: DateTime(2021),
        amount: Decimal.one,
      ),
    ),
    expect: () => [
      isA<ComparisonFailure>().having(
        (state) => state.error,
        'typed replay error',
        isA<InvalidScenarioReplayError>(),
      ),
    ],
    verify: (_) => verifyZeroInteractions(compare),
  );

  blocTest<ComparisonBloc, ComparisonState>(
    'replay geçersiz tarih/tutarla sessiz no-op yerine typed failure üretir',
    build: build,
    seed: () => ComparisonAssetsLoaded(
      assets: [
        asset('A', DateTime(2020), DateTime(2023)),
        asset('B', DateTime(2020), DateTime(2023)),
      ],
    ),
    act: (bloc) => bloc.add(
      ComparisonReplayRequested(
        symbols: const ['A', 'B'],
        buyDate: DateTime(2019),
        amount: Decimal.parse('1.001'),
      ),
    ),
    expect: () => [
      isA<ComparisonFailure>().having(
        (state) => state.error,
        'typed replay error',
        isA<InvalidScenarioReplayError>(),
      ),
    ],
    verify: (_) => verifyZeroInteractions(compare),
  );
}
