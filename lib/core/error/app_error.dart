/// Uygulama genelinde kullanılan hata kategorileri.
/// Domain katmanı bunu kullanır — Dio/HTTP bağımlılığı yoktur.
sealed class AppError {
  const AppError();
}

/// Sunucu bu tarih için fiyat verisi döndürmedi.
class PriceNotFoundError extends AppError {
  const PriceNotFoundError();
}

/// Günlük ücretsiz hesaplama limiti doldu.
class DailyLimitError extends AppError {
  final DateTime resetAt;
  const DailyLimitError({required this.resetAt});
}

/// Cihazın internet bağlantısı yok.
class NoInternetError extends AppError {
  const NoInternetError();
}

/// Sunucu beklenmeyen bir hata döndürdü.
class ServerError extends AppError {
  final int? statusCode;
  const ServerError({this.statusCode});
}

/// Bilinmeyen / yakalanamayan hata.
class UnknownError extends AppError {
  final Object? cause;
  const UnknownError({this.cause});
}
