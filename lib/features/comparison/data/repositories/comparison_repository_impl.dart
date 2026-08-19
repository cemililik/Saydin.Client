import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/response_body_validator.dart';
import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/features/comparison/data/models/compare_result_model.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/domain/repositories/comparison_repository.dart';

/// Dio çağrısını yapar ve `DioException`'ı bu katmanda [AppError]'a
/// dönüştürür — BLoC Dio import etmez (F-10-12). Beklenmedik parse hataları
/// (FormatException/TypeError) burada YAKALANMAZ; BLoC'un generic catch'inde
/// [UnknownError]'a sarılır.
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
    required Decimal amount,
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
          'amount': MoneyParser.toJsonString(amount),
          'amountType': amountType,
          'includeInflation': includeInflation,
        },
      );
      final data = ResponseBodyValidator.requireMap(response.data);
      return ResponseBodyValidator.parse(() {
        final result = CompareResultModel.fromJson(data);
        _validateRequestedSymbols(result, assetSymbols);
        return result;
      });
    } on DioException catch (e) {
      throw _errorMapper.map(e);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static void _validateRequestedSymbols(
    CompareResult result,
    List<String> requestedSymbols,
  ) {
    final returned = result.results
        .map((item) => item.calculation.assetSymbol)
        .toList(growable: false);
    if (returned.length != requestedSymbols.length ||
        returned.toSet().length != returned.length ||
        !requestedSymbols.every(returned.contains)) {
      throw const FormatException(
        'compare result: istenen ve dönen varlık sembolleri eşleşmiyor',
      );
    }
  }
}
