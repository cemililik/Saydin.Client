import 'package:decimal/decimal.dart';

import '../entities/compare_result.dart';
import '../repositories/comparison_repository.dart';

class CompareWhatIf {
  final ComparisonRepository _repository;
  final DateTime Function() _clock;

  CompareWhatIf(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  Future<CompareResult> call({
    required List<String> assetSymbols,
    required DateTime buyDate,
    DateTime? sellDate,
    required Decimal amount,
    required String amountType,
    bool includeInflation = false,
  }) async {
    final result = await _repository.compare(
      assetSymbols: assetSymbols,
      buyDate: buyDate,
      sellDate: sellDate,
      amount: amount,
      amountType: amountType,
      includeInflation: includeInflation,
    );
    final calculatedAt = _clock();
    return CompareResult(
      results: result.results
          .map(
            (item) => CompareResultItem(
              rank: item.rank,
              calculation: item.calculation.withCalculatedAt(calculatedAt),
            ),
          )
          .toList(growable: false),
    );
  }
}
