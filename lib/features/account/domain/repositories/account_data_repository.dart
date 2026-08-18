/// Hesap (kullanıcı verisi) silme akışını yöneten repository sözleşmesi.
///
/// KVKK 6698 Madde 11 ve GDPR Madde 17 ("unutulma hakkı") kapsamında
/// kullanıcının tüm yerel verilerini geri dönüşsüz olarak silme yükümlülüğü
/// vardır. Yerel silme, silme isteğinin backend tarafından kabul edildiği
/// doğrulandıktan sonra başlar; böylece istek başarısız olduğunda tekrar deneme
/// için kullanılan cihaz kimliği kaybedilmez.
abstract class AccountDataRepository {
  /// Backend'in silmeyi 200/204 ile doğruladığını, yerel cleanup tamamen
  /// bitene kadar process restart'larından bağımsız saklar. Marker kullanıcı
  /// verisi taşımaz; yalnızca idempotent cleanup fazını ifade eder.
  Future<void> markLocalCleanupPending();

  /// Önceki bir denemede backend doğrulandı fakat local cleanup tamamlanmadıysa
  /// `true` döner. Bu durumda backend DELETE tekrar edilmez.
  Future<bool> hasPendingLocalCleanup();

  /// Bütün local cleanup adımları tamamlandıktan sonra phase marker'ını siler.
  Future<void> clearPendingLocalCleanup();

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

  /// Backend'e hesap silme talebi gönderir.
  /// Sadece silmenin tamamlandığını doğrulayan **200/204** yanıtı için `true`
  /// döner. 202 Accepted, status sorgulama protokolü henüz olmadığı için
  /// doğrulanmış silme sayılmaz. 404, 501 veya başka durumlarda (`backend hazır değil`,
  /// `endpoint not implemented`, `network`) `false` döner. Bu durumda çağıran
  /// **local wipe yapmamalı**; aynı device identity ile güvenli tekrar deneme
  /// mümkün kalmalıdır. Uygulama hata gösterir ve kullanıcı tekrar dener.
  /// Hiçbir koşulda exception fırlatmaz.
  Future<bool> requestBackendDeletion();
}
