import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Sertifika pinleme: TLS handshake'inde sunucu sertifika zincirinde beklenen
/// SHA-256 fingerprint'i bulunmazsa istek reddedilir.
///
/// Pin formatı: `sha256/<base64-encoded-DER-hash>` veya `<hex hash>`.
/// `--dart-define=PINNED_CERT_SHA256=hash1,hash2` ile virgülle ayrılmış
/// liste verilir. Hash'ler sertifikanın DER-encoded byte'larının SHA-256
/// digest'idir (`openssl x509 -in cert.pem -outform DER | openssl dgst
/// -sha256`).
///
/// **Tasarım kararı — opt-in:**
///   - Pin verilmezse pinning DEVRE DIŞI kalır ve sistem trust store
///     standart şekilde kullanılır.
///   - Bu, dev ortamda ngrok sertifika rotasyonunda uygulamayı
///     bozmamayı garanti eder.
///
/// **⚠ Önemli — production'da hâlâ aktive edilmedi:**
/// `release.yml` AAB ve IPA build adımlarında `PINNED_CERT_SHA256`
/// dart-define geçirilmiyor; production sertifikaların SHA-256'sı
/// kararlaştığında release workflow'una eklenecek. O zamana kadar
/// production build'leri sistem trust store ile korunur — yeterli
/// ama pinning'in MITM ekstra koruması devre dışı. Bu kodda pinning
/// altyapısı hazır, sadece dart-define aktivasyonu eksik.
///
/// **Pin rotasyon yöntemi (aktive edildiğinde):** En az 2 fingerprint
/// pinlenmeli — primary (mevcut cert) + backup (next rotation cert).
/// Cert rotate edilince app güncellenmeden bozulmaz. Let's Encrypt 90
/// günlük döngüde leaf cert hash sıkça değişir; backup pin zorunlu.
///
/// **Hash yöntemi — leaf cert DER (SPKI değil):** `sha256.convert(
/// cert.der)` LEAF sertifikanın tamamını hash'ler. Alternatif SPKI
/// (Subject Public Key Info) hash daha sağlam (cert yenilenince key
/// aynı kalırsa SPKI sabit) ama mevcut implementation leaf hash; pin
/// rotasyon stratejisinin bunu hesaba katması şart.
class CertificatePinning {
  const CertificatePinning._();

  /// Pin listesi — `--dart-define` ile gelir. Boş ise pinning kapalı.
  static const _pinnedFingerprintsRaw = String.fromEnvironment(
    'PINNED_CERT_SHA256',
    defaultValue: '',
  );

  /// Parse edilmiş ve normalize edilmiş (lowercase, no whitespace) SHA-256
  /// hex hash listesi.
  static final Set<String> _pinnedFingerprints = _parsePins(
    _pinnedFingerprintsRaw,
  );

  /// Pinning aktif mi? Test'lerden override edilebilir.
  static bool get isEnabled => _pinnedFingerprints.isNotEmpty;

  /// `Dio` instance'ına `IOHttpClientAdapter` üzerinden pin kontrolü ekler.
  /// Aktif pin yoksa no-op — mevcut adapter korunur.
  static void apply(Dio dio) {
    if (!isEnabled) return;
    final pinned = _pinnedFingerprints;
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          // System trust store reddetti — düz reject.
          // (`badCertificateCallback` yalnızca trust store reddinde çağrılır.)
          if (kDebugMode) {
            debugPrint(
              '[CertificatePinning] System trust rejected cert for $host:$port',
            );
          }
          return false;
        };
        return client;
      },
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
        final fingerprint = sha256.convert(cert.der).toString().toLowerCase();
        final ok = pinned.contains(fingerprint);
        if (!ok && kDebugMode) {
          debugPrint(
            '[CertificatePinning] Pin mismatch for $host: got $fingerprint',
          );
        }
        return ok;
      },
    );
  }

  /// Test/diag amaçlı: input string'i normalize set'e çevir.
  @visibleForTesting
  static Set<String> parsePinsForTest(String raw) => _parsePins(raw);

  static Set<String> _parsePins(String raw) {
    if (raw.trim().isEmpty) return const <String>{};
    return raw
        .split(',')
        .map((p) => p.trim().toLowerCase())
        // `sha256/` veya `sha256:` prefix'ini soy.
        .map((p) => p.startsWith('sha256/') ? p.substring(7) : p)
        .map((p) => p.startsWith('sha256:') ? p.substring(7) : p)
        .where((p) => p.isNotEmpty)
        .toSet();
  }
}
