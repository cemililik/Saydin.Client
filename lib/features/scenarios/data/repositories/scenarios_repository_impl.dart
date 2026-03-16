import 'package:dio/dio.dart';
import 'package:saydin/features/scenarios/data/models/saved_scenario_model.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/domain/repositories/scenarios_repository.dart';

class ScenariosRepositoryImpl implements ScenariosRepository {
  final Dio _dio;

  ScenariosRepositoryImpl(this._dio);

  @override
  Future<List<SavedScenario>> getScenarios() async {
    final response = await _dio.get<List<dynamic>>('/v1/scenarios');
    final list = response.data ?? [];
    return list
        .map((e) => SavedScenarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SavedScenario> saveScenario({
    required String assetSymbol,
    required String assetDisplayName,
    required DateTime buyDate,
    DateTime? sellDate,
    required num amount,
    required String amountType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/scenarios',
      data: {
        'assetSymbol': assetSymbol,
        'assetDisplayName': assetDisplayName,
        'buyDate': _formatDate(buyDate),
        if (sellDate != null) 'sellDate': _formatDate(sellDate),
        'amount': amount,
        'amountType': amountType,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Senaryo yanıtı boş geldi.');
    }
    return SavedScenarioModel.fromJson(data);
  }

  @override
  Future<void> deleteScenario(String id) async {
    await _dio.delete<void>('/v1/scenarios/$id');
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
