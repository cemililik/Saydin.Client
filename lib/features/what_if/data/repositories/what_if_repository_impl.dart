import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/features/what_if/data/models/asset_model.dart';
import 'package:saydin/features/what_if/data/models/reverse_what_if_response_model.dart';
import 'package:saydin/features/what_if/data/models/what_if_response_model.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';

/// Dio çağrılarını yapar ve `DioException`'ı bu katmanda [AppError]'a
/// dönüştürür — BLoC katmanı Dio import etmez (CLAUDE.md "BLoC'ta HTTP YASAK";
/// F-07-02). Yalnızca `DioException` eşlenir; beklenmedik parse hataları
/// (FormatException/TypeError) burada YAKALANMAZ — BLoC'un generic catch'ine
/// düşüp [UnknownError]'a sarılır (sözleşme: tipli ağ hataları AppError,
/// beklenmedikler UnknownError).
class WhatIfRepositoryImpl implements WhatIfRepository {
  final Dio _dio;
  final DioErrorMapper _errorMapper;

  WhatIfRepositoryImpl(this._dio, [this._errorMapper = const DioErrorMapper()]);

  @override
  Future<List<Asset>> getAssets() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.assets,
      );
      final list = (response.data?['assets'] as List<dynamic>?) ?? [];
      return list
          .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<WhatIfResult> calculate({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
    bool includeInflation = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.whatIfCalculate,
        data: {
          'assetSymbol': assetSymbol,
          'buyDate': _formatDate(buyDate),
          if (sellDate != null) 'sellDate': _formatDate(sellDate),
          'amount': amount,
          'amountType': amountType,
          'includeInflation': includeInflation,
        },
      );
      final data = response.data;
      // 2xx + boş gövde sunucu sözleşme ihlalidir → MalformedResponseError
      // (F-07-08). `ServerError(statusCode: 200)` anlamsal olarak tuhaftı;
      // "başarı statüsü ama eksik gövde" durumu artık ayrı varyantla taşınır.
      if (data == null) {
        throw const MalformedResponseError();
      }
      return WhatIfResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<ReverseWhatIfResult> calculateReverse({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required num targetAmount,
    required String targetAmountType,
    bool includeInflation = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.whatIfReverse,
        data: {
          'assetSymbol': assetSymbol,
          'buyDate': _formatDate(buyDate),
          if (sellDate != null) 'sellDate': _formatDate(sellDate),
          'targetAmount': targetAmount,
          'targetAmountType': targetAmountType,
          'includeInflation': includeInflation,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const MalformedResponseError();
      }
      return ReverseWhatIfResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _errorMapper.map(e);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
