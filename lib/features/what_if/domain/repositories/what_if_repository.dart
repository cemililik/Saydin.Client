import '../entities/asset.dart';
import '../entities/reverse_what_if_result.dart';
import '../entities/what_if_result.dart';

abstract class WhatIfRepository {
  Future<List<Asset>> getAssets();
  Future<WhatIfResult> calculate({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
    bool includeInflation = false,
  });
  Future<ReverseWhatIfResult> calculateReverse({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required num targetAmount,
    required String targetAmountType,
    bool includeInflation = false,
  });
}
