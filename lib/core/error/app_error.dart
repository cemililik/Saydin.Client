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

/// Talep edilen özellik kullanıcının mevcut planında kapalı — backend bunu
/// HTTP 403 + `https://saydin.app/errors/feature-disabled` ProblemDetails ile
/// bildirir (PaidUpgradeRequired semantiği). Bir sunucu hatası DEĞİLDİR:
/// beklenen bir iş kuralıdır, bu yüzden Sentry'ye raporlanmaz (BLoC'lardaki
/// raporlama gate'i yalnızca [UnknownError]/[ServerError]/[MalformedResponseError]'ı kapsar).
///
/// [featureKey] backend `feature` extension'ından gelir
/// (`inflation` | `comparison` | `extended_history` | `dca`) ve özelliğe özgü
/// paywall mesajını seçmek için kullanılır; `null`/bilinmeyen ise genel
/// "planınızda kullanılamıyor" mesajına düşülür.
class FeatureDisabledError extends AppError {
  final String? featureKey;
  const FeatureDisabledError({this.featureKey});
}

/// Sunucu bir kaynağın bulunamadığını bildirdi, ancak RFC-7807 `type` alanı
/// bunu fiyat veya varlık gibi kullanıcıya anlamlı, endpoint-özel bir hataya
/// bağlamaya yetmiyor. Böyle bir 404'ü [PriceNotFoundError]'a indirgemek yanlış
/// ekrana yanlış açıklama gösterebilir.
class NotFoundError extends AppError {
  const NotFoundError();
}

/// Sunucu erişimi reddetti, ancak sözleşmedeki `feature-disabled` tipi ile
/// doğrulanmış bir plan kapısı yok. Böyle bir 403'ü paywall olarak göstermek
/// yanlış yönlendirme olur; çağıran bunu endpoint-nötr hata olarak ele alır.
class ForbiddenError extends AppError {
  const ForbiddenError();
}

/// Cihazın internet bağlantısı yok.
class NoInternetError extends AppError {
  const NoInternetError();
}

/// İstek, kullanıcı veya ekran yaşam döngüsü tarafından iptal edildi.
/// Bu bir bağlantı/sunucu arızası değildir ve telemetride hata olarak
/// raporlanmamalıdır. İptal edilen ekranda sonuç artık gösterilmediği için
/// çağıran katman bunu sessizce yok sayabilir.
class RequestCancelledError extends AppError {
  const RequestCancelledError();
}

/// Kaydedilmiş senaryo güncel şema veya finansal form invariant'larına
/// güvenle taşınamıyor. Bu, sunucu arızası değil; eski/bozuk payload için
/// kullanıcıya açık fakat raporlanmayan bir replay sonucudur.
class InvalidScenarioReplayError extends AppError {
  const InvalidScenarioReplayError();
}

/// Sunucu beklenmeyen bir hata döndürdü.
class ServerError extends AppError {
  final int? statusCode;
  const ServerError({this.statusCode});
}

/// Sunucu 2xx döndürdü ama gövde **boş/eksik** — sözleşme ihlali (F-07-08).
/// [ServerError]'dan ayrı tutulur: `ServerError` HTTP hata statüsünü (4xx/5xx)
/// temsil eder; `MalformedResponseError` ise "başarı statüsü ama gövde yok"
/// durumudur (örn. 200 + `null` body). Böylece `ServerError(statusCode: 200)`
/// gibi anlamsal olarak tuhaf bir değer üretmek zorunda kalmayız.
///
/// Finansal repository'ler doğrulanmış 2xx gövdesindeki `FormatException` ve
/// `TypeError`ı da bu varyanta sarar: HTTP başarılı olsa bile zorunlu alanın
/// eksik/yanlış tipte olması aynı sunucu sözleşmesi ihlalidir. İstekten bağımsız
/// programlama hataları ise [UnknownError] olarak kalır. [cause], hangi alanın
/// kontratı bozduğunu telemetride ayırmak için korunur.
class MalformedResponseError extends AppError {
  final Object? cause;
  const MalformedResponseError({this.cause});
}

/// Bilinmeyen / yakalanamayan hata.
class UnknownError extends AppError {
  final Object? cause;
  const UnknownError({this.cause});
}
