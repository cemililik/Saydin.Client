import 'package:dio/dio.dart';
import 'app_error.dart';

/// Dio exception'larını domain AppError'a dönüştürür.
/// BLoC ve repository katmanları Dio'yu doğrudan bilmez.
class DioErrorMapper {
  const DioErrorMapper();

  AppError map(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return const NoInternetError();
    }

    final status = e.response?.statusCode;

    if (status == 404) return const PriceNotFoundError();

    // Backend/proxy bazen non-Map gövde döndürür (HTML hata sayfası, düz
    // string, List). `dynamic` üzerinde `[]` erişimi o durumda
    // NoSuchMethodError fırlatır ve `on DioException` handler'ını atlatırdı.
    // Önce Map'e daralt; değilse alan okumaları atlanır, ServerError'a düşülür.
    final data = _asMap(e.response?.data);
    final ext = _asMap(data?['extensions']);

    if (status == 422) {
      final type = data?['type'];
      if (type == 'https://saydin.app/errors/scenario-limit-exceeded') {
        final limitRaw = ext?['limit'];
        final limit = limitRaw is num ? limitRaw.toInt() : 5;
        return ScenarioLimitError(limit: limit);
      }
    }

    if (status == 429) {
      final resetAtRaw = ext?['resetAt'];
      final resetAt = resetAtRaw is String
          ? DateTime.tryParse(resetAtRaw) ?? _tomorrowMidnight()
          : _tomorrowMidnight();
      return DailyLimitError(resetAt: resetAt);
    }

    return ServerError(statusCode: status);
  }

  /// `dynamic` gövdeyi güvenle `Map<String, dynamic>`'e daraltır; Map değilse
  /// `null`. Index erişiminden önce çağrılır (blind cast/NoSuchMethodError önler).
  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      // `Map<String,dynamic>.from` non-String key'de `k as String` ile
      // TypeError atardı (hot path'te). Key'leri toString ile güvenle çevir.
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static DateTime _tomorrowMidnight() {
    final nowUtc = DateTime.now().toUtc();
    final tomorrowUtc = nowUtc.add(const Duration(days: 1));
    return DateTime.utc(tomorrowUtc.year, tomorrowUtc.month, tomorrowUtc.day);
  }
}
