import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/features/config/data/models/app_config_model.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  final Dio _dio;

  AppConfigRepositoryImpl(this._dio);

  @override
  Future<AppConfig> getConfig() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.appConfig,
    );
    return AppConfigModel.fromJson(response.data!);
  }
}
