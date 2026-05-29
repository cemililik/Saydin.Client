import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/features/dca/data/models/dca_response_model.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/domain/repositories/dca_repository.dart';

/// Dio çağrısını yapar ve `DioException`'ı bu katmanda [AppError]'a
/// dönüştürür — BLoC Dio import etmez (F-08-17). Beklenmedik parse hataları
/// (FormatException/TypeError) burada YAKALANMAZ; BLoC'un generic catch'inde
/// [UnknownError]'a sarılır.
class DcaRepositoryImpl implements DcaRepository {
  final Dio _dio;
  final DioErrorMapper _errorMapper;

  DcaRepositoryImpl(this._dio, [this._errorMapper = const DioErrorMapper()]);

  @override
  Future<DcaResult> calculate({
    required String assetSymbol,
    required DateTime startDate,
    DateTime? endDate,
    required num periodicAmount,
    required String period,
    required String amountType,
    bool includeInflation = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.dcaCalculate,
        data: {
          'assetSymbol': assetSymbol,
          'startDate': _formatDate(startDate),
          if (endDate != null) 'endDate': _formatDate(endDate),
          'periodicAmount': periodicAmount,
          'period': period,
          'amountType': amountType,
          'includeInflation': includeInflation,
        },
      );
      final data = response.data;
      // 200 + boş gövde → ServerError (hardcoded TR FormatException yerine).
      if (data == null) {
        throw ServerError(statusCode: response.statusCode);
      }
      return DcaResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _errorMapper.map(e);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
