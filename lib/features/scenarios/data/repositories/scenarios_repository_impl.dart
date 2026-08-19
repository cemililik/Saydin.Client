import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/error/response_body_validator.dart';
import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/features/scenarios/data/models/saved_scenario_model.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/domain/repositories/scenarios_repository.dart';

/// Dio çağrılarını yapar ve `DioException`'ı bu katmanda [AppError]'a
/// dönüştürür — BLoC Dio import etmez. Silme idempotency'si (404 = zaten yok)
/// de burada ele alınır (F-11-03 semantiği data katmanına taşındı). Beklenmedik
/// Satır parse hataları izole edilip raporlanır; top-level 2xx gövde sözleşmesi
/// ise fail-closed [MalformedResponseError] üretir.
class ScenariosRepositoryImpl implements ScenariosRepository {
  final Dio _dio;
  final DioErrorMapper _errorMapper;
  final ErrorReporter _reporter;

  ScenariosRepositoryImpl(
    this._dio, {
    DioErrorMapper errorMapper = const DioErrorMapper(),
    ErrorReporter reporter = const ErrorReporter(),
  }) : _errorMapper = errorMapper,
       _reporter = reporter;

  @override
  Future<List<SavedScenario>> getScenarios({String plan = 'free'}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.scenarios,
        queryParameters: {'plan': plan},
      );
      final list = ResponseBodyValidator.requireList(response.data);
      // Tek bozuk/eksik satır (örn. geçersiz tarih) tüm senaryo listesini
      // düşürmesin: her satırı izole et, hatalıyı atla ve raporla. Kullanıcı
      // diğer geçerli senaryolarını görmeye devam eder.
      final scenarios = <SavedScenario>[];
      for (final e in list) {
        try {
          scenarios.add(SavedScenarioModel.fromJson(e as Map<String, dynamic>));
        } catch (err, st) {
          // Raporlamayı await ETME: birden çok bozuk satırda ardışık ağ
          // istekleri döngüyü bloklayıp geçerli senaryoların gösterimini
          // geciktirir. Arka planda fire-and-forget.
          unawaited(_reporter.report(err, st, context: 'get_scenarios_parse'));
        }
      }
      return scenarios;
    } on DioException catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<SavedScenario> saveScenario({
    required String assetSymbol,
    required String assetDisplayName,
    required DateTime buyDate,
    DateTime? sellDate,
    required Decimal amount,
    required String amountType,
    ScenarioType type = ScenarioType.whatIf,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.scenarios,
        data: {
          'assetSymbol': assetSymbol,
          'assetDisplayName': assetDisplayName,
          'buyDate': _formatDate(buyDate),
          if (sellDate != null) 'sellDate': _formatDate(sellDate),
          'amount': MoneyParser.toJsonString(amount),
          'amountType': amountType,
          'type': _typeToString(type),
          if (extraData != null) 'extraData': extraData,
        },
      );
      final data = ResponseBodyValidator.requireMap(response.data);
      return ResponseBodyValidator.parse(
        () => SavedScenarioModel.fromJson(data),
      );
    } on DioException catch (e) {
      throw _errorMapper.map(e);
    }
  }

  @override
  Future<void> deleteScenario(String id) async {
    try {
      await _dio.delete<void>('${ApiEndpoints.scenarios}/$id');
    } on DioException catch (e) {
      // F-11-03: silme idempotent. 404 = kaynak zaten yok (sunucuda silinmiş /
      // çift dokunuş) = istenen son durum → sessiz başarı, hata fırlatma.
      // (Mapper 404'ü PriceNotFoundError'a indirgediği için ham status'e bakılır.)
      if (e.response?.statusCode == 404) return;
      throw _errorMapper.map(e);
    }
  }

  static String _typeToString(ScenarioType type) => switch (type) {
    ScenarioType.whatIf => 'what_if',
    ScenarioType.comparison => 'comparison',
    ScenarioType.portfolio => 'portfolio',
    ScenarioType.dca => 'dca',
  };

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
