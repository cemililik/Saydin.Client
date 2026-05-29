import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Sertifika pinleme: TLS handshake sonunda sunucu sertifikanın beklenen
/// SHA-256 fingerprint'i bulunmazsa istek reddedilir.
///
/// **Pin formatı (hex-only):** Sertifika DER bytes'ının SHA-256 hex
/// digest'i. `--dart-define=PINNED_CERT_SHA256=hex1,hex2` ile virgülle
/// ayrılmış liste verilir. Hash hesaplaması:
/// ```
/// openssl x509 -in cert.pem -outform DER | openssl dgst -sha256
/// ```
/// Çıktı `(stdin)= <hex>` formatında — sadece hex kısmını kullan. Opsiyonel
/// `sha256/` veya `sha256:` prefix'i kabul edilir (yalnızca prefix soyulur,
/// kalan kısmın hex olduğu varsayılır). **Base64 desteklenmiyor** —
/// kullanıcı önce base64'ü hex'e çevirmeli (`base64 -d | xxd -p -c 64`).
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
        // Dio'nun default _createHttpClient() idleTimeout=3s set eder; özel
        // createHttpClient geçtiğimiz için o default devre dışı kalır ve
        // dart:io default'una (15s) düşerdi. Aynı 3s'i koru (bağlantı
        // havuzu davranışı pinning aktive edildiğinde tutarlı kalsın).
        final client = HttpClient()..idleTimeout = const Duration(seconds: 3);
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
        final ok = matchesPin(cert?.der, pinned);
        if (!ok && kDebugMode && cert != null) {
          final fingerprint = sha256.convert(cert.der).toString().toLowerCase();
          debugPrint(
            '[CertificatePinning] Pin mismatch for $host: got $fingerprint',
          );
        }
        return ok;
      },
    );
  }

  /// Pin karşılaştırma çekirdeği — `validateCertificate` callback'inin saf,
  /// test edilebilir özü. `der` null ise (cert yok) reddet; aksi halde
  /// SHA-256 hex digest pin set'inde var mı kontrol et.
  @visibleForTesting
  static bool matchesPin(List<int>? der, Set<String> pinned) {
    if (der == null) return false;
    final fingerprint = sha256.convert(der).toString().toLowerCase();
    return pinned.contains(fingerprint);
  }

  /// Test/diag amaçlı: input string'i normalize set'e çevir.
  @visibleForTesting
  static Set<String> parsePinsForTest(String raw) => _parsePins(raw);

  static final _hexRegex = RegExp(r'^[0-9a-f]{64}$');

  static Set<String> _parsePins(String raw) {
    if (raw.trim().isEmpty) return const <String>{};
    final pins = <String>{};
    for (final rawPin in raw.split(',')) {
      var p = rawPin.trim().toLowerCase();
      if (p.isEmpty) continue;
      // `sha256/` veya `sha256:` prefix'ini soy.
      if (p.startsWith('sha256/')) p = p.substring(7);
      if (p.startsWith('sha256:')) p = p.substring(7);
      // Hex (64 char = 32 byte SHA-256) doğrula. Malformed → fail-loud:
      // sessiz drop pin'siz çalışmaya çevirir, MITM koruması illüzyonu
      // yaratır. Pin tanımlandıysa doğru tanımlı OLMALI.
      if (!_hexRegex.hasMatch(p)) {
        throw StateError(
          'PINNED_CERT_SHA256 entry is not a valid 64-char lowercase hex '
          'SHA-256 digest: "$rawPin". Use openssl dgst -sha256 output '
          '(hex). Base64 not supported.',
        );
      }
      pins.add(p);
    }
    return pins;
  }
}
