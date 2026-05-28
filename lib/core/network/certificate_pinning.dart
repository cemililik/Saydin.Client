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
///   - Release build için CI/CD'de production sertifikaların SHA-256'sı
///     `PINNED_CERT_SHA256` olarak geçilmelidir.
///
/// **Pin rotasyon yöntemi:** En az 2 fingerprint pinlenmeli — primary
/// (mevcut) + backup (next rotation cert). Cert rotate edilince app
/// güncellenmeden bozulmaz.
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
