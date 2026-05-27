/// Hesap (kullanıcı verisi) silme akışını yöneten repository sözleşmesi.
///
/// KVKK 6698 Madde 11 ve GDPR Madde 17 ("unutulma hakkı") kapsamında
/// kullanıcının tüm yerel verilerini geri dönüşsüz olarak silme yükümlülüğü
/// vardır. Backend tarafında bir hesap kavramı henüz yok; gelecekte API
/// hazırlandığında [requestBackendDeletion] gerçek bir endpoint çağıracak.
abstract class AccountDataRepository {
  /// Cihaz üzerindeki TÜM kullanıcı verilerini siler:
  /// - SharedPreferences (tüm anahtarlar)
  /// - SecureStorage (cihaz UUID'si dahil)
  /// - Uygulama cache dizini (paylaşılan PNG snapshot'lar vs.)
  ///
  /// Geri dönüşsüzdür. Çağıran taraf onay almalıdır.
  Future<void> wipeLocalData();

  /// Backend'e en iyi-çaba (best-effort) hesap silme talebi gönderir.
  /// Backend hazır olmadığında veya 404 dönmediğinde [Future] sessizce
  /// `true` döner; başka hata varsa `false` döner. Hiçbir koşulda
  /// exception fırlatmaz — yerel silme her zaman önceliklidir.
  Future<bool> requestBackendDeletion();
}
