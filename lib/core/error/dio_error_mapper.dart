import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'app_error.dart';

/// Dio exception'larını domain [AppError]'a dönüştürür.
/// BLoC ve repository katmanları Dio'yu doğrudan bilmez.
///
/// **Backend sözleşmesi (RFC-7807 ProblemDetails).** Saydın API hataları
/// `application/problem+json` döndürür ve ayırt edici alan `type` URI'sidir
/// (örn. `https://saydin.app/errors/daily-limit-exceeded`). Backend'deki
/// `IExceptionHandler` zinciri her domain exception için sabit bir `type` +
/// HTTP status üretir. Bu yüzden mapper **önce `type`'a**, yoksa HTTP status'e
/// bakar (F-05-11). `api-contract.md`'deki eski `{ "error": "CODE" }` zarfı
/// güncel değildir — kaynak doğrusu backend `*ExceptionHandler.cs` dosyalarıdır.
///
/// **Extensions düzleştirme.** ASP.NET `ProblemDetails.Extensions`'ı
/// `[JsonExtensionData]` ile **üst seviyeye düzleştirerek** serialize eder:
/// `{ "type": ..., "status": 429, "limit": 10, "resetAt": "..." }` — nested
/// bir `"extensions"` objesi olarak DEĞİL. Eski mapper yalnızca nested okuyup
/// gerçek `resetAt`/`limit`'i kaçırıyordu; `resetAt` yalnızca fallback değeri
/// (yarın UTC gece yarısı) backend'in hesabıyla birebir aynı olduğu için bu
/// hata gözden kaçmıştı. Burada hem düz hem nested okunur (savunmacı).
class DioErrorMapper {
  const DioErrorMapper();

  static const _errorBase = 'https://saydin.app/errors/';

  AppError map(DioException e) {
    // ── Ağ seviyesi (HTTP yanıtı yok) ─────────────────────────────────────
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        // Bağlantı sınıfı: kopma + tüm timeout'lar → NoInternetError. Mobilde
        // sık görülür; kullanıcıya "bağlantını kontrol et" ve Sentry'ye
        // raporlanmaz. Eskiden timeout'lar ServerError(null)'a düşüp hem
        // gürültü hem yanıltıcı "sunucu hatası" üretiyordu (M-1).
        return const NoInternetError();
      case DioExceptionType.unknown:
        // F-05-10: `unknown` çoğu zaman beklenmeyen bir hatadır (cast/iptal).
        // AMA Dio v5'te gerçek bağlantı kopması SocketException olarak `unknown`
        // içinde yüzeye çıkabilir → onu NoInternet'e indir (M-2). HandshakeException
        // SocketException ALT TÜRÜ DEĞİLDİR; sertifika/güvenlik sinyali olarak
        // UnknownError'da kalır ve raporlanır.
        if (e.error is SocketException) return const NoInternetError();
        return UnknownError(cause: e.error ?? e);
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
        // Aşağıda status/type ile ele alınır. badCertificate güvenlik sinyali
        // olarak ServerError'a düşüp raporlanır (kasıtlı). cancel bu uygulamada
        // CancelToken kullanılmadığından pratikte oluşmaz.
        break;
    }

    final data = _asMap(e.response?.data);
    final status = e.response?.statusCode;

    // ── RFC-7807 `type` URI birincil ayraç ────────────────────────────────
    final type = data?['type'];
    if (type is String && type.startsWith(_errorBase)) {
      switch (type.substring(_errorBase.length)) {
        case 'price-not-found':
          return const PriceNotFoundError();
        case 'asset-not-found':
          return const AssetNotFoundError();
        case 'scenario-limit-exceeded':
          return ScenarioLimitError(limit: _intExtension(data, 'limit') ?? 5);
        case 'daily-limit-exceeded':
          return DailyLimitError(resetAt: _resetAt(data));
        // L-3: `scenario-not-found` (404) kasıtlı olarak ele alınmıyor.
        // İstemcide tek 404-üreten senaryo yolu deleteScenario'dur ve orada 404
        // idempotent başarı olarak (mapper'dan ÖNCE) yutulur; tekil senaryo
        // GET-by-id yoktur → bu type pratikte mapper'a ulaşmaz, status 404
        // fallback'inde PriceNotFoundError'a düşer (zararsız). İleride tekil
        // senaryo GET eklenirse burada bir ScenarioNotFoundError varyantı + case
        // gerekir (aksi halde yanlış "fiyat bulunamadı" mesajı çıkar).
      }
      // Diğer tanınan tipler (validation/feature-disabled/external-api/
      // internal-error) için ayrı bir AppError varyantı yok → status fallback
      // ile ServerError'a düşerler. (feature-disabled paywall'ı Faz 4.)
    }

    // ── `type` yok/tanınmıyor → HTTP status (savunma + eski sözleşme) ──────
    if (status == 404) return const PriceNotFoundError();
    if (status == 429) return DailyLimitError(resetAt: _resetAt(data));

    return ServerError(statusCode: status);
  }

  /// Limit alanını önce düz (`data['limit']`), sonra nested
  /// (`data['extensions']['limit']`) konumdan okur; sayı değilse `null`.
  static int? _intExtension(Map<String, dynamic>? data, String key) {
    final raw = data?[key] ?? _asMap(data?['extensions'])?[key];
    return raw is num ? raw.toInt() : null;
  }

  /// `resetAt`'i düz/nested okuyup ISO-8601 (offset'li `O` formatı dahil)
  /// parse eder; yoksa yarın UTC gece yarısına düşer.
  static DateTime _resetAt(Map<String, dynamic>? data) {
    final raw = data?['resetAt'] ?? _asMap(data?['extensions'])?['resetAt'];
    if (raw is String) {
      return DateTime.tryParse(raw) ?? _tomorrowMidnight();
    }
    return _tomorrowMidnight();
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
