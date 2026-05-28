import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/features/dca/data/models/dca_response_model.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/domain/repositories/dca_repository.dart';

class DcaRepositoryImpl implements DcaRepository {
  final Dio _dio;
  DcaRepositoryImpl(this._dio);

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
    if (data == null) {
      throw const FormatException('DCA yanıtı boş geldi.');
    }
    return DcaResponseModel.fromJson(data);
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
