import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saydin/core/storage/share_card_cache.dart';
import 'package:share_plus/share_plus.dart';

/// Paylaşım kartı render edilemediğinde fırlatılır (F-05-22). Eskiden bu
/// durumlar sessizce `return` ediliyordu: kullanıcı "Paylaş"a basıyor, hiçbir
/// şey olmuyor ve neden olduğu hiçbir yere yazılmıyordu. Artık tipli hata
/// fırlatılır; çağıran katman kullanıcıya snackbar gösterir ve Sentry'ye
/// raporlar.
class ShareCardException implements Exception {
  /// Makine-okunur sebep (PII içermez — Sentry'ye güvenle gider):
  /// `boundary_null` (RepaintBoundary context'i yok) veya
  /// `encode_failed` (PNG byte kodlaması başarısız) ya da
  /// `share_origin_invalid` (iPad popover anchor'ı güvenli değil).
  final String reason;
  const ShareCardException(this.reason);

  @override
  String toString() => 'ShareCardException($reason)';
}

/// Native paylaşım sağlayıcısını renderer'dan ayıran test seam'i.
///
/// iPad popover anchor'ı interface seviyesinde zorunludur; yeni bir sağlayıcı
/// eklenirse origin'i sessizce düşüremez.
abstract interface class ShareGateway {
  Future<ShareGatewayResult> shareFile({
    required String filePath,
    required String mimeType,
    required String text,
    required Rect sharePositionOrigin,
  });
}

/// Platform plugin sonucunun uygulama-içi, plugin bağımsız karşılığı.
enum ShareGatewayResult { success, dismissed, unavailable }

/// Paylaşım hattının platform eklentisinden bağımsız sonucu.
///
/// [denied], paylaşım yetkisinin render başlamadan önce veya native ekran
/// açılmadan hemen önce geri çekildiğini ifade eder.
enum ShareDeliveryResult { completed, dismissed, unavailable, denied }

class SharePlusGateway implements ShareGateway {
  const SharePlusGateway();

  @override
  Future<ShareGatewayResult> shareFile({
    required String filePath,
    required String mimeType,
    required String text,
    required Rect sharePositionOrigin,
  }) async {
    if (!ShareCardRenderer.isValidSharePositionOrigin(sharePositionOrigin)) {
      throw const ShareCardException('share_origin_invalid');
    }
    final result = await Share.shareXFiles(
      [XFile(filePath, mimeType: mimeType)],
      text: text,
      sharePositionOrigin: sharePositionOrigin,
    );
    return switch (result.status) {
      ShareResultStatus.success => ShareGatewayResult.success,
      ShareResultStatus.dismissed => ShareGatewayResult.dismissed,
      ShareResultStatus.unavailable => ShareGatewayResult.unavailable,
    };
  }
}

/// [RepaintBoundary] ile işaretlenmiş widget'ı PNG olarak yakalar ve
/// platform paylaşım sayfasını açar.
///
/// [caption], native hedefe gönderilecek önceden tamamlanmış metindir. Renderer
/// yerelleştirme çözmez, CTA eklemez ve metni hiçbir biçimde değiştirmez.
///
/// Render başarısız olursa [ShareCardException] fırlatır — çağıran katman
/// yakalayıp kullanıcıya geri bildirir ve raporlar.
class ShareCardRenderer {
  ShareCardRenderer._();

  static const _targetPx = 1080.0;
  static const _defaultGateway = SharePlusGateway();

  /// Geçici share kart dosyaları için merkezi cache sözleşmesindeki prefix.
  static const String filePrefix = ShareCardCache.filePrefix;

  /// Native share popover'ını CTA'ya bağlayan global rect'i üretir.
  ///
  /// `share_plus` bu alanı iPad'de zorunlu tutar. Sıfır boyutlu, finite olmayan
  /// veya görünür viewport'la kesişmeyen bir rect ile native çağrı yapılmaz.
  static Rect sharePositionOriginFromKey(
    GlobalKey key, {
    required Rect viewport,
  }) {
    final renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      throw const ShareCardException('share_origin_invalid');
    }

    final origin = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    return validatedSharePositionOrigin(origin, viewport: viewport);
  }

  @visibleForTesting
  static Rect validatedSharePositionOrigin(
    Rect? origin, {
    required Rect viewport,
  }) {
    if (origin == null ||
        !isValidSharePositionOrigin(origin) ||
        !isValidSharePositionOrigin(viewport) ||
        !origin.overlaps(viewport)) {
      throw const ShareCardException('share_origin_invalid');
    }
    return origin;
  }

  @visibleForTesting
  static bool isValidSharePositionOrigin(Rect origin) =>
      origin.isFinite &&
      !origin.isEmpty &&
      origin.width > 0 &&
      origin.height > 0;

  /// Renderer ile native plugin arasındaki typed seam'i tek yerde uygular.
  /// Testler platform channel açmadan origin ve request aktarımını doğrular.
  @visibleForTesting
  static Future<ShareDeliveryResult> distributeShareFile({
    required String filePath,
    required String mimeType,
    required String caption,
    required Rect sharePositionOrigin,
    required ShareGateway gateway,
    required bool Function() canExecuteShare,
  }) async {
    if (!isValidSharePositionOrigin(sharePositionOrigin)) {
      throw const ShareCardException('share_origin_invalid');
    }
    // Yetki kontrolüyle native gateway arasında başka async iş bırakma.
    if (!canExecuteShare()) return ShareDeliveryResult.denied;

    final result = await gateway.shareFile(
      filePath: filePath,
      mimeType: mimeType,
      text: caption,
      sharePositionOrigin: sharePositionOrigin,
    );
    return switch (result) {
      ShareGatewayResult.success => ShareDeliveryResult.completed,
      ShareGatewayResult.dismissed => ShareDeliveryResult.dismissed,
      ShareGatewayResult.unavailable => ShareDeliveryResult.unavailable,
    };
  }

  static Future<ShareDeliveryResult> shareFromKey(
    GlobalKey key, {
    required String caption,
    required Rect viewport,
    required Rect sharePositionOrigin,
    required bool Function() canExecuteShare,
    ShareGateway gateway = _defaultGateway,
    Future<Directory> Function() temporaryDirectoryProvider =
        getTemporaryDirectory,
  }) async {
    // Yetki yoksa origin, boundary, encoder, dosya sistemi ve gateway dahil
    // paylaşım hattında hiçbir aksiyon alma.
    if (!canExecuteShare()) return ShareDeliveryResult.denied;

    validatedSharePositionOrigin(sharePositionOrigin, viewport: viewport);

    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    // F-05-22: sessiz `return` yerine tipli hata — kullanıcı "Paylaş"a basıp
    // hiçbir şey olmaması + sebebin hiçbir yere yazılmaması durumunu kır.
    if (boundary == null) {
      throw const ShareCardException('boundary_null');
    }

    // Ekranda hangi boyutta render edildiğine bakmaksızın 1080px çıktı üret.
    final displayWidth = boundary.size.width;
    final pixelRatio = displayWidth > 0 ? _targetPx / displayWidth : 2.0;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await encodePngAndDispose(image);
    if (byteData == null) {
      throw const ShareCardException('encode_failed');
    }

    final bytes = byteData.buffer.asUint8List();
    return deliverRenderedBytes(
      bytes: bytes,
      caption: caption,
      sharePositionOrigin: sharePositionOrigin,
      canExecuteShare: canExecuteShare,
      gateway: gateway,
      temporaryDirectoryProvider: temporaryDirectoryProvider,
    );
  }

  /// Render tamamlandıktan sonraki dosya ve native teslimat sınırı.
  ///
  /// Ayrı tutulması, native gateway öncesi canlı yetki kontrolü ile kaynak
  /// dosyanın bütün sonuçlarda temizlenmesini platform kanalı olmadan sınar.
  @visibleForTesting
  static Future<ShareDeliveryResult> deliverRenderedBytes({
    required Uint8List bytes,
    required String caption,
    required Rect sharePositionOrigin,
    required bool Function() canExecuteShare,
    required ShareGateway gateway,
    required Future<Directory> Function() temporaryDirectoryProvider,
  }) async {
    final tempDir = await temporaryDirectoryProvider();
    final file = File(
      '${tempDir.path}/$filePrefix${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    try {
      return await distributeShareFile(
        filePath: file.path,
        mimeType: 'image/png',
        caption: caption,
        sharePositionOrigin: sharePositionOrigin,
        gateway: gateway,
        canExecuteShare: canExecuteShare,
      );
    } finally {
      // Share sonucu döndüğünde uygulamanın kaynak PNG'sini sil. Android'de
      // share_plus native intent'i açmadan önce bu kaynağı kendi provider
      // cache'ine kopyalar; o kopyanın ayrı retention sözleşmesini
      // ShareCardCache yönetir. Kaynak silme başarısız olursa sessizce geç —
      // startup cleanup ikinci savunma hattı.
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {
        /* best-effort */
      }
    }
  }

  /// PNG encoding başarılı olsa da hata verse de yüksek çözünürlüklü native
  /// image kaynağını aynı async frame içinde serbest bırakır.
  @visibleForTesting
  static Future<ByteData?> encodePngAndDispose(ui.Image image) async {
    try {
      return await image.toByteData(format: ui.ImageByteFormat.png);
    } finally {
      image.dispose();
    }
  }

  /// Uygulama açılışında çağrılır: 1 saatten eski `saydin_share_*.png`
  /// kaynaklarını ve Android'deki aynı adlı `share_plus` kopyalarını siler.
  /// Önceki oturumda paylaşım iletişim kutusu kapanmadan uygulama kapatılırsa
  /// [shareFromKey] finally bloğu çalışmaz — startup cleanup ikinci savunma
  /// hattıdır.
  ///
  /// Eşik 1 saat: bir paylaşım hedef uygulaması (WhatsApp vb.) henüz
  /// dosyayı tüketmediği için aktif iletişim kutusu kapanmadan bekleyen
  /// dosyaları kaçırırız. Pratikte share session 1 saatten uzun sürmez.
  ///
  /// [maxKept] LRU üst sınırıdır: 1 saatten yeni dosyalar bile bu sayıyı
  /// aşarsa en eski olanlar silinir. Kullanıcı kısa sürede çok sayıda
  /// paylaşım denerse veya force-quit ile finally bloğu kaçırırsa diskte
  /// finansal görsel birikimi engellenir (KVKK Madde 12 minimizasyon).
  static Future<void> cleanupStaleShareFiles({
    Duration olderThan = const Duration(hours: 1),
    int maxKept = 20,
    Future<Directory> Function() temporaryDirectoryProvider =
        getTemporaryDirectory,
    bool? includeAndroidPluginCache,
  }) async {
    try {
      final tempDir = await temporaryDirectoryProvider();
      await ShareCardCache.cleanupStale(
        temporaryDirectory: tempDir,
        olderThan: olderThan,
        maxKept: maxKept,
        includeAndroidPluginCache:
            includeAndroidPluginCache ?? Platform.isAndroid,
      );
    } catch (_) {
      /* best-effort overall */
    }
  }
}
