import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Her isteğe `X-Device-ID` header'ı ekler. ID `FlutterSecureStorage`'da
/// kalıcıdır; storage erişilemezse oturum-içi **sabit** bir ephemeral ID
/// kullanılır.
///
/// **F-05-14 / F-14-11 — ephemeral kararlılık.** İki garanti:
///  1. ID önce üretilip cache'lenir, **sonra** diske yazılır → yazma başarısız
///     olsa bile aynı oturumda aynı ID kullanılır (üretilen değer atılmaz).
///  2. İlk çözümleme tek bir in-flight `Future` üzerinden tekilleştirilir →
///     açılışta paralel gelen isteklerin (örn. 5 BLoC'un eşzamanlı asset
///     çekişi) her birinin ayrı ephemeral ID üretip farklı `X-Device-ID`
///     göndermesi engellenir.
class DeviceIdInterceptor extends Interceptor {
  static const _storageKey = 'saydin_device_id';
  final FlutterSecureStorage _storage;

  DeviceIdInterceptor(this._storage);

  String? _cachedDeviceId;
  Future<String>? _inFlight;

  /// Çözümleme "kuşağı". resetCache her çağrıldığında artar; devam eden bir
  /// [_resolveDeviceId] tamamlanırken kuşak değiştiyse cache'e YAZMAZ —
  /// böylece hesap silme sırasında uçuşta olan bir çözümleme, silinmiş eski
  /// ID'yi cache'e geri koyamaz (L-2 hardening).
  int _epoch = 0;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['X-Device-ID'] = await _getOrCreateDeviceId();
    handler.next(options);
  }

  /// In-memory cache'i (ve devam eden ilk çözümlemeyi) temizler. Hesap silme
  /// akışı sonrası çağrılır; aksi takdirde eski UUID aynı oturumda taşınır ve
  /// silinmiş SecureStorage'a rağmen sonraki istekler eski tanımlayıcıyı
  /// gönderir (KVKK Madde 11 ihlali).
  void resetCache() {
    _cachedDeviceId = null;
    _inFlight = null;
    _epoch++;
  }

  Future<String> _getOrCreateDeviceId() {
    final cached = _cachedDeviceId;
    if (cached != null) return Future<String>.value(cached);
    // İlk çözümlemeyi tekilleştir: paralel istekler AYNI Future'ı bekler →
    // hepsi aynı ID'yi alır (ephemeral path'te bile divergence olmaz).
    return _inFlight ??= _resolveDeviceId();
  }

  Future<String> _resolveDeviceId() async {
    // Bu çözümlemenin kuşağı; tamamlanırken reset araya girdiyse cache'e yazma.
    final myEpoch = _epoch;
    try {
      final stored = await _storage.read(key: _storageKey);
      if (stored != null) {
        if (myEpoch == _epoch) _cachedDeviceId = stored;
        return stored;
      }
      // İlk kez: üret + ÖNCE cache'le (oturum kararlılığı), SONRA kalıcı yaz.
      // Yazma çökerse aşağıdaki catch aynı üretilmiş ID'yi korur.
      final generated = const Uuid().v4();
      if (myEpoch == _epoch) _cachedDeviceId = generated;
      await _storage.write(key: _storageKey, value: generated);
      return generated;
    } catch (_) {
      // Storage erişilemez (read/write çöktü). Üretilmiş bir ID varsa onu KORU;
      // yoksa bir kez üret ve sabitle — oturum boyunca değişmez.
      final ephemeral = _cachedDeviceId ?? const Uuid().v4();
      if (myEpoch == _epoch) _cachedDeviceId = ephemeral;
      return ephemeral;
    }
  }
}
