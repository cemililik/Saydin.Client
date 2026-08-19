import 'package:decimal/decimal.dart';

import '../entities/compare_result.dart';

abstract class ComparisonRepository {
  Future<CompareResult> compare({
    required List<String> assetSymbols,
    required DateTime buyDate,
    DateTime? sellDate,
    required Decimal amount,
    required String amountType,
    bool includeInflation = false,
  });
}
