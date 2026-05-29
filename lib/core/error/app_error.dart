/// Uygulama genelinde kullanılan hata kategorileri.
/// Domain katmanı bunu kullanır — Dio/HTTP bağımlılığı yoktur.
sealed class AppError {
  const AppError();
}

/// Sunucu bu tarih için fiyat verisi döndürmedi.
class PriceNotFoundError extends AppError {
  const PriceNotFoundError();
}

/// İstenen varlık sembolü backend tarafından tanınmıyor (404
/// `asset-not-found`). Önceden tüm 404'ler [PriceNotFoundError]'a
/// indirgeniyordu; bu, silinmiş/listeden kalkmış bir varlığa işaret eden
/// kayıtlı senaryo replay'inde "fiyat bulunamadı" gibi yanıltıcı bir mesaj
/// üretiyordu. Backend ProblemDetails `type` URI'siyle ayırt edilir (F-05-11).
class AssetNotFoundError extends AppError {
  const AssetNotFoundError();
}

/// Günlük ücretsiz hesaplama limiti doldu.
class DailyLimitError extends AppError {
  final DateTime resetAt;
  const DailyLimitError({required this.resetAt});
}

/// Ücretsiz senaryo kaydetme limiti doldu.
class ScenarioLimitError extends AppError {
  final int limit;
  const ScenarioLimitError({required this.limit});
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

/// Sunucu 2xx döndürdü ama gövde boş/ayrıştırılamaz — sözleşme ihlali
/// (F-07-08). [ServerError]'dan ayrı tutulur: `ServerError` HTTP hata
/// statüsünü (4xx/5xx) temsil eder; `MalformedResponseError` ise "başarı
/// statüsü ama beklenmeyen/eksik gövde" durumudur (örn. 200 + `null` body
/// ya da `fromJson` parse hatası). Böylece `ServerError(statusCode: 200)`
/// gibi anlamsal olarak tuhaf bir değer üretmek zorunda kalmayız.
class MalformedResponseError extends AppError {
  final Object? cause;
  const MalformedResponseError({this.cause});
}

/// Bilinmeyen / yakalanamayan hata.
class UnknownError extends AppError {
  final Object? cause;
  const UnknownError({this.cause});
}
