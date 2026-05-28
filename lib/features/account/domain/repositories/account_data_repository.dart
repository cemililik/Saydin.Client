/// Hesap (kullanıcı verisi) silme akışını yöneten repository sözleşmesi.
///
/// KVKK 6698 Madde 11 ve GDPR Madde 17 ("unutulma hakkı") kapsamında
/// kullanıcının tüm yerel verilerini geri dönüşsüz olarak silme yükümlülüğü
/// vardır. Backend tarafında bir hesap kavramı henüz yok; gelecekte API
/// hazırlandığında [requestBackendDeletion] gerçek bir endpoint çağıracak.
abstract class AccountDataRepository {
  /// Cihaz üzerindeki TÜM kullanıcı verilerini siler:
  /// - `SharedPreferences` (tüm anahtarlar — tercihler, onboarding flag,
  ///   KVKK acceptance, vs.)
  /// - `FlutterSecureStorage` (cihaz UUID'si dahil tüm anahtarlar)
  /// - `getTemporaryDirectory()/saydin_share_*.png` paylaşım kart kopyaları
  /// - In-memory device ID cache (`DeviceIdInterceptor._cachedDeviceId`)
  ///
  /// Geri dönüşsüzdür. Çağıran taraf onay almalıdır.
  /// Kısmen başarısızsa `AccountWipeException` fırlatır; çağıran kısmi
  /// başarıyı kullanıcıya bildirmelidir.
  Future<void> wipeLocalData();

  /// Backend'e en iyi-çaba (best-effort) hesap silme talebi gönderir.
  /// Sadece **2xx** yanıt için `true` döner ("kayıt gerçekten silindi").
  /// 404, 501 veya başka non-2xx durumlarda (`backend hazır değil`,
  /// `endpoint not implemented`, `network`) `false` döner — UI bunu
  /// `AccountDeletionPartialSuccess` olarak gösterir ve kullanıcı
  /// iletisim@saydin.app üzerinden takip eder.
  /// Hiçbir koşulda exception fırlatmaz — yerel silme her zaman
  /// önceliklidir.
  Future<bool> requestBackendDeletion();
}
