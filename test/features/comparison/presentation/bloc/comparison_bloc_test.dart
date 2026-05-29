import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_event.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_state.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';

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

  group('ComparisonBloc — F-10-02 buyDate null guard', () {
    // Eski kod loaded.buyDate! ile crash ederdi; guard hiçbir state emit
    // etmeden döner. expect [] hem crash hem yanlış emit'i yakalar.
    blocTest<ComparisonBloc, ComparisonState>(
      'onCalculateRequested_buyDateNull_noEmitNoCrash',
      build: build,
      seed: () => const ComparisonAssetsLoaded(
        assets: [],
        selectedSymbols: ['USDTRY', 'BTC'],
        amount: 1000,
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
}
