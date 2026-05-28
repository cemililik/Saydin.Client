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
  /// Backend hazır olmadığında veya `404`/`501` döndüğünde [Future]
  /// sessizce `true` döner (silme zaten yapılmış / endpoint henüz yoksa
  /// yerel wipe yeterli kabul edilir). Başka hata varsa `false` döner.
  /// Hiçbir koşulda exception fırlatmaz — yerel silme her zaman
  /// önceliklidir.
  Future<bool> requestBackendDeletion();
}
