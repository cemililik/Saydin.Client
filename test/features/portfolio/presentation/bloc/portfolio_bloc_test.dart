import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/portfolio_constants.dart';
import 'package:saydin/features/portfolio/domain/usecases/calculate_portfolio.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_event.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_state.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';

class MockGetAssets extends Mock implements GetAssets {}

class MockCalculatePortfolio extends Mock implements CalculatePortfolio {}

void main() {
  late MockGetAssets getAssets;
  late MockCalculatePortfolio calc;

  setUp(() {
    getAssets = MockGetAssets();
    calc = MockCalculatePortfolio();
  });

  PortfolioBloc build() => PortfolioBloc(getAssets, calc);

  PortfolioItem item(int i) => PortfolioItem(
    id: 'id-$i',
    assetSymbol: 'A$i',
    assetDisplayName: 'Asset $i',
    amount: 100,
    amountType: 'try',
  );

  List<PortfolioItem> items(int n) => List.generate(n, item);

  PortfolioItemAdded addEvent() => const PortfolioItemAdded(
    assetSymbol: 'NEW',
    assetDisplayName: 'New',
    amount: 100,
    amountType: 'try',
  );

  group('PortfolioBloc — F-09-09 maxItems guard', () {
    blocTest<PortfolioBloc, PortfolioState>(
      'limit altında ekleme → liste büyür',
      build: build,
      seed: () => PortfolioEditing(items: items(2)),
      act: (b) => b.add(addEvent()),
      expect: () => [
        isA<PortfolioEditing>().having((s) => s.items.length, 'items', 3),
      ],
    );

    blocTest<PortfolioBloc, PortfolioState>(
      'maxItems\'tayken ekleme no-op (state emit edilmez, liste büyümez)',
      build: build,
      seed: () => PortfolioEditing(items: items(PortfolioConstants.maxItems)),
      act: (b) => b.add(addEvent()),
      expect: () => const <PortfolioState>[],
    );
  });
}
