import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/features/comparison/data/models/compare_result_model.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/domain/repositories/comparison_repository.dart';

class ComparisonRepositoryImpl implements ComparisonRepository {
  final Dio _dio;
  ComparisonRepositoryImpl(this._dio);

  @override
  Future<CompareResult> compare({
    required List<String> assetSymbols,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
    bool includeInflation = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.whatIfCompare,
      data: {
        'assetSymbols': assetSymbols,
        'buyDate': _formatDate(buyDate),
        if (sellDate != null) 'sellDate': _formatDate(sellDate),
        'amount': amount,
        'amountType': amountType,
        'includeInflation': includeInflation,
      },
    );
    final data = response.data;
    if (data == null) throw const FormatException('Compare yanıtı boş geldi.');
    return CompareResultModel.fromJson(data);
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
