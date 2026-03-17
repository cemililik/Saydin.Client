import '../entities/asset.dart';
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
}
