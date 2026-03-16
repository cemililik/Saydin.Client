import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/features/what_if/data/models/asset_model.dart';
import 'package:saydin/features/what_if/data/models/what_if_response_model.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';

class WhatIfRepositoryImpl implements WhatIfRepository {
  final Dio _dio;
  WhatIfRepositoryImpl(this._dio);

  @override
  Future<List<Asset>> getAssets() async {
    final response = await _dio.get<List<dynamic>>(ApiEndpoints.assets);
    return (response.data ?? [])
        .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WhatIfResult> calculate({
    required String assetSymbol,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.whatIfCalculate,
      data: {
        'assetSymbol': assetSymbol,
        'buyDate': _formatDate(buyDate),
        if (sellDate != null) 'sellDate': _formatDate(sellDate),
        'amount': amount,
        'amountType': amountType,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('WhatIf yanıtı boş geldi.');
    }
    return WhatIfResponseModel.fromJson(data);
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
