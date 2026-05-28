import '../entities/compare_result.dart';
import '../repositories/comparison_repository.dart';

class CompareWhatIf {
  final ComparisonRepository _repository;
  CompareWhatIf(this._repository);

  Future<CompareResult> call({
    required List<String> assetSymbols,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
    bool includeInflation = false,
  }) => _repository.compare(
    assetSymbols: assetSymbols,
    buyDate: buyDate,
    sellDate: sellDate,
    amount: amount,
    amountType: amountType,
    includeInflation: includeInflation,
  );
}
