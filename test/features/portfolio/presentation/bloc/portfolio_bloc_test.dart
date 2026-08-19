import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/portfolio/domain/portfolio_constants.dart';
import 'package:saydin/features/portfolio/domain/usecases/calculate_portfolio.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_event.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_state.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';

class MockGetAssets extends Mock implements GetAssets {}

class MockCalculatePortfolio extends Mock implements CalculatePortfolio {}

void main() {
  late MockGetAssets getAssets;
  late MockCalculatePortfolio calc;
  late Completer<PortfolioResult> firstCompleter;
  late Completer<PortfolioResult> secondCompleter;

  setUp(() {
    getAssets = MockGetAssets();
    calc = MockCalculatePortfolio();
  });

  setUpAll(() {
    registerFallbackValue(DateTime(2020));
    registerFallbackValue(<PortfolioItem>[]);
  });

  PortfolioBloc build() => PortfolioBloc(getAssets, calc);

  PortfolioItem item(int i) => PortfolioItem(
    id: 'id-$i',
    assetSymbol: 'A$i',
    assetDisplayName: 'Asset $i',
    amount: Decimal.fromInt(100),
    amountType: 'try',
  );

  List<PortfolioItem> items(int n) => List.generate(n, item);

  Asset asset(int i) =>
      Asset(symbol: 'A$i', displayName: 'Asset $i', category: 'currency');

  Asset newAsset() =>
      const Asset(symbol: 'NEW', displayName: 'New', category: 'currency');

  PortfolioItemAdded addEvent() => PortfolioItemAdded(
    assetSymbol: 'NEW',
    assetDisplayName: 'New',
    amount: Decimal.fromInt(100),
    amountType: 'try',
  );

  PortfolioResult result(String finalValue, {DateTime? effectiveSellDate}) =>
      PortfolioResult(
        items: [
          PortfolioItemResult(
            item: item(0),
            calculation: PortfolioCalculation(
              initialValueTry: Decimal.fromInt(100),
              finalValueTry: Decimal.parse(finalValue),
              profitLossPercent: 10,
              isProfit: true,
            ),
            sharePercent: 100,
          ),
        ],
        totalInitialValueTry: Decimal.fromInt(100),
        totalFinalValueTry: Decimal.parse(finalValue),
        totalProfitLossTry: Decimal.parse(finalValue) - Decimal.fromInt(100),
        totalProfitLossPercent: 10,
        isProfit: true,
        effectiveSellDate: effectiveSellDate,
      );

  group('PortfolioBloc — F-09-09 maxItems guard', () {
    blocTest<PortfolioBloc, PortfolioState>(
      'onItemAdded_belowMaxItems_appendsItem',
      build: build,
      seed: () => PortfolioEditing(
        assets: [asset(0), asset(1), newAsset()],
        items: items(2),
      ),
      act: (b) => b.add(addEvent()),
      expect: () => [
        isA<PortfolioEditing>().having((s) => s.items.length, 'items', 3),
      ],
    );

    blocTest<PortfolioBloc, PortfolioState>(
      'onItemAdded_atMaxItems_noOp',
      build: build,
      seed: () => PortfolioEditing(
        assets: [
          ...List.generate(PortfolioConstants.maxItems, asset),
          newAsset(),
        ],
        items: items(PortfolioConstants.maxItems),
      ),
      act: (b) => b.add(addEvent()),
      expect: () => const <PortfolioState>[],
    );

    blocTest<PortfolioBloc, PortfolioState>(
      'scale sınırını aşan tutar state sınırında reddedilir',
      build: build,
      seed: () => const PortfolioEditing(),
      act: (bloc) => bloc.add(
        PortfolioItemAdded(
          assetSymbol: 'NEW',
          assetDisplayName: 'New',
          amount: Decimal.parse('1.001'),
          amountType: 'try',
        ),
      ),
      expect: () => const <PortfolioState>[],
    );
  });

  group('PortfolioBloc — request snapshot', () {
    blocTest<PortfolioBloc, PortfolioState>(
      'ters sırada tamamlanan eski cevap yeni sonucu ezmez',
      build: build,
      setUp: () {
        final first = Completer<PortfolioResult>();
        final second = Completer<PortfolioResult>();
        var callCount = 0;
        when(
          () => calc(
            items: any(named: 'items'),
            buyDate: any(named: 'buyDate'),
            sellDate: any(named: 'sellDate'),
            includeInflation: any(named: 'includeInflation'),
          ),
        ).thenAnswer((_) => callCount++ == 0 ? first.future : second.future);
        addTearDown(() {
          if (!first.isCompleted) first.complete(result('110'));
          if (!second.isCompleted) second.complete(result('120'));
        });
        // Completer'ları act'e güvenli biçimde aktar.
        firstCompleter = first;
        secondCompleter = second;
      },
      seed: () => PortfolioEditing(
        assets: [asset(0)],
        items: [item(0)],
        buyDate: DateTime(2020),
      ),
      act: (bloc) async {
        bloc.add(const PortfolioCalculateRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(PortfolioBuyDateChanged(DateTime(2021)));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PortfolioCalculateRequested());
        await Future<void>.delayed(Duration.zero);
        secondCompleter.complete(result('120'));
        await Future<void>.delayed(Duration.zero);
        firstCompleter.complete(result('110'));
      },
      expect: () => [
        isA<PortfolioCalculating>().having(
          (s) => s.buyDate,
          'first buyDate',
          DateTime(2020),
        ),
        isA<PortfolioEditing>().having(
          (s) => s.buyDate,
          'edited buyDate',
          DateTime(2021),
        ),
        isA<PortfolioCalculating>().having(
          (s) => s.buyDate,
          'second buyDate',
          DateTime(2021),
        ),
        isA<PortfolioSuccess>()
            .having((s) => s.buyDate, 'success buyDate', DateTime(2021))
            .having(
              (s) => s.result.totalFinalValueTry,
              'latest result',
              Decimal.fromInt(120),
            ),
      ],
    );

    blocTest<PortfolioBloc, PortfolioState>(
      'dil değişimi sonucu korur ve portföy hesabını çağırmaz',
      build: build,
      setUp: () => when(() => getAssets()).thenAnswer(
        (_) async => [
          const Asset(
            symbol: 'A0',
            displayName: 'Localized Asset 0',
            category: 'x',
          ),
        ],
      ),
      seed: () => PortfolioSuccess(
        assets: const [
          Asset(symbol: 'A0', displayName: 'Asset 0', category: 'x'),
        ],
        items: [item(0)],
        buyDate: DateTime(2020),
        result: result('110', effectiveSellDate: DateTime(2024, 6, 15)),
      ),
      act: (bloc) => bloc.add(const PortfolioLanguageChanged()),
      expect: () => [
        isA<PortfolioSuccess>()
            .having(
              (s) => s.result.totalFinalValueTry,
              'preserved result',
              Decimal.fromInt(110),
            )
            .having(
              (s) => s.result.items.single.item.assetDisplayName,
              'localized result name',
              'Localized Asset 0',
            )
            .having(
              (s) => s.result.effectiveSellDate,
              'effective sell date snapshot',
              DateTime(2024, 6, 15),
            ),
      ],
      verify: (_) => verifyZeroInteractions(calc),
    );
  });

  group('PortfolioBloc — asset tarih kesişimi', () {
    final first = Asset(
      symbol: 'A0',
      displayName: 'A0',
      category: 'currency',
      firstDate: DateTime(2020),
      lastDate: DateTime(2021),
    );
    final second = Asset(
      symbol: 'A1',
      displayName: 'A1',
      category: 'currency',
      firstDate: DateTime(2022),
      lastDate: DateTime(2023),
    );

    blocTest<PortfolioBloc, PortfolioState>(
      'örtüşmesiz kalem eklendiğinde eski tarihler atomik temizlenir',
      build: build,
      seed: () => PortfolioEditing(
        assets: [first, second],
        items: [item(0)],
        buyDate: DateTime(2020, 6),
        sellDate: DateTime(2020, 12),
      ),
      act: (bloc) => bloc.add(
        PortfolioItemAdded(
          assetSymbol: 'A1',
          assetDisplayName: 'A1',
          amount: Decimal.fromInt(100),
          amountType: 'try',
        ),
      ),
      expect: () => [
        isA<PortfolioEditing>()
            .having((state) => state.buyDate, 'buyDate', isNull)
            .having((state) => state.sellDate, 'sellDate', isNull),
      ],
    );

    blocTest<PortfolioBloc, PortfolioState>(
      'örtüşmesiz snapshot hesaplama use case çağrısını engeller',
      build: build,
      seed: () => PortfolioEditing(
        assets: [first, second],
        items: [item(0), item(1)],
        buyDate: DateTime(2022),
      ),
      act: (bloc) => bloc.add(const PortfolioCalculateRequested()),
      expect: () => const <PortfolioState>[],
      verify: (_) => verifyZeroInteractions(calc),
    );
  });

  blocTest<PortfolioBloc, PortfolioState>(
    'tüm kalemler typed hatayla başarısızsa neden genericleşmeden taşınır',
    build: build,
    setUp: () => when(
      () => calc(
        items: any(named: 'items'),
        buyDate: any(named: 'buyDate'),
        sellDate: any(named: 'sellDate'),
        includeInflation: any(named: 'includeInflation'),
      ),
    ).thenThrow(const NoInternetError()),
    seed: () => PortfolioEditing(
      assets: [asset(0)],
      items: [item(0)],
      buyDate: DateTime(2020),
    ),
    act: (bloc) => bloc.add(const PortfolioCalculateRequested()),
    expect: () => [
      isA<PortfolioCalculating>(),
      isA<PortfolioFailure>().having(
        (state) => state.error,
        'typed error',
        isA<NoInternetError>(),
      ),
    ],
  );

  blocTest<PortfolioBloc, PortfolioState>(
    'replay duplicate varlıkla normal form invariantını atlayamaz',
    build: build,
    seed: () => PortfolioEditing(assets: [asset(0)]),
    act: (bloc) => bloc.add(
      PortfolioReplayRequested(
        items: [
          item(0),
          PortfolioItem(
            id: 'duplicate-id',
            assetSymbol: 'A0',
            assetDisplayName: 'Duplicate Asset 0',
            amount: Decimal.fromInt(200),
            amountType: 'try',
          ),
        ],
        buyDate: DateTime(2020),
      ),
    ),
    expect: () => [
      isA<PortfolioFailure>().having(
        (state) => state.error,
        'typed replay error',
        isA<InvalidScenarioReplayError>(),
      ),
    ],
    verify: (_) => verifyZeroInteractions(calc),
  );

  blocTest<PortfolioBloc, PortfolioState>(
    'replay stored displayName yerine güncel katalog adını kullanır',
    build: build,
    setUp: () => when(
      () => calc(
        items: any(named: 'items'),
        buyDate: any(named: 'buyDate'),
        sellDate: any(named: 'sellDate'),
        includeInflation: any(named: 'includeInflation'),
      ),
    ).thenAnswer((_) async => result('110')),
    seed: () => const PortfolioEditing(
      assets: [
        Asset(
          symbol: 'A0',
          displayName: 'Current Catalog Name',
          category: 'currency',
        ),
      ],
    ),
    act: (bloc) => bloc.add(
      PortfolioReplayRequested(
        items: [
          PortfolioItem(
            id: 'stored-id',
            assetSymbol: 'A0',
            assetDisplayName: 'Stale Stored Name',
            amount: Decimal.fromInt(100),
            amountType: 'try',
          ),
        ],
        buyDate: DateTime(2020),
      ),
    ),
    expect: () => [
      isA<PortfolioEditing>().having(
        (state) => state.items.single.assetDisplayName,
        'current display name',
        'Current Catalog Name',
      ),
      isA<PortfolioCalculating>(),
      isA<PortfolioSuccess>(),
    ],
    verify: (_) {
      final captured =
          verify(
                () => calc(
                  items: captureAny(named: 'items'),
                  buyDate: any(named: 'buyDate'),
                  sellDate: any(named: 'sellDate'),
                  includeInflation: any(named: 'includeInflation'),
                ),
              ).captured.single
              as List<PortfolioItem>;
      expect(captured.single.assetDisplayName, 'Current Catalog Name');
    },
  );
}
