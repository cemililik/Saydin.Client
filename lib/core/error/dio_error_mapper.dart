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

    if (status == 429) {
      final resetAtRaw = e.response?.data?['extensions']?['resetAt'] as String?;
      final resetAt = resetAtRaw != null
          ? DateTime.tryParse(resetAtRaw) ?? _tomorrowMidnight()
          : _tomorrowMidnight();
      return DailyLimitError(resetAt: resetAt);
    }

    return ServerError(statusCode: status);
  }

  static DateTime _tomorrowMidnight() => DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day + 1,
  );
}
