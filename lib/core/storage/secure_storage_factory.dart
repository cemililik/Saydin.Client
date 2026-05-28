import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// `FlutterSecureStorage` için merkezi opsiyon kaynağı.
///
/// Varsayılan constructor (`FlutterSecureStorage()`) iOS'ta `accessibility`
/// `unlocked` (default), Android'de `encryptedSharedPreferences = false`
/// kullanır. Default yapılandırma:
///  - iOS Keychain item'larını iCloud Keychain'e backup'lar → uygulamayı
///    kaldırınca "veriler silinir" vaadiyle çelişir.
///  - Android'de AES-EncryptedSharedPreferences yerine eski (plaintext) SP
///    fallback'ine düşebilir.
///
/// `create()` bu opsiyonları uygulayarak KVKK Madde 12 (veri güvenliği) için
/// minimum donanım/OS koruma seviyesini garanti eder.
class SecureStorageFactory {
  const SecureStorageFactory._();

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  /// Yeni bir `FlutterSecureStorage` instance'ı döner. Caller her seferinde
  /// yeni instance alabilir — `FlutterSecureStorage` thin wrapper'dır,
  /// platform channel altta tek kanaldır.
  static FlutterSecureStorage create() {
    return const FlutterSecureStorage(
      iOptions: _iosOptions,
      aOptions: _androidOptions,
    );
  }
}
