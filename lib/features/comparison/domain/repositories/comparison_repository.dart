import '../entities/compare_result.dart';

abstract class ComparisonRepository {
  Future<CompareResult> compare({
    required List<String> assetSymbols,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
    bool includeInflation = false,
  });
}
