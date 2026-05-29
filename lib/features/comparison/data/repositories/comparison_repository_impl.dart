import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/features/comparison/data/models/compare_result_model.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/domain/repositories/comparison_repository.dart';

/// Dio çağrısını yapar ve `DioException`'ı bu katmanda [AppError]'a
/// dönüştürür — BLoC yalnızca [AppError] görür (F-10-12).
class ComparisonRepositoryImpl implements ComparisonRepository {
  final Dio _dio;
  final DioErrorMapper _errorMapper;

  ComparisonRepositoryImpl(
    this._dio, [
    this._errorMapper = const DioErrorMapper(),
  ]);

  @override
  Future<CompareResult> compare({
    required List<String> assetSymbols,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
    bool includeInflation = false,
  }) async {
    try {
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
      // 200 + boş gövde → ServerError (hardcoded TR FormatException yerine).
      if (data == null) {
        throw ServerError(statusCode: response.statusCode);
      }
      return CompareResultModel.fromJson(data);
    } on DioException catch (e) {
      throw _errorMapper.map(e);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
