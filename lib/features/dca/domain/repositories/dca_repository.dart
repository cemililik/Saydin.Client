import 'package:decimal/decimal.dart';

import '../entities/dca_result.dart';

abstract class DcaRepository {
  Future<DcaResult> calculate({
    required String assetSymbol,
    required DateTime startDate,
    DateTime? endDate,
    required Decimal periodicAmount,
    required String period,
    required String amountType,
    bool includeInflation = false,
  });
}
