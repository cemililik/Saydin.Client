import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:share_plus/share_plus.dart';

/// [RepaintBoundary] ile işaretlenmiş widget'ı PNG olarak yakalar ve
/// platform paylaşım sayfasını açar.
///
/// [shareText]: WhatsApp / Twitter gibi uygulamalarda görünecek metin.
/// Belirtilmezse varsayılan marka metni kullanılır.
class ShareCardRenderer {
  ShareCardRenderer._();

  static const _targetPx = 1080.0;

  /// Geçici share kart dosyaları için sabit prefix. `account_data_repository`
  /// ve [cleanupStaleShareFiles] bu prefix'i bekler — değiştirilmemeli.
  static const String filePrefix = 'saydin_share_';

  static Future<void> shareFromKey(
    GlobalKey key, {
    String? shareText,
    required BuildContext context,
  }) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    // Resolve l10n before async gap.
    final l10n = context.l10n;
    final text = (shareText ?? l10n.shareDefaultText) + l10n.shareCta;

    // Ekranda hangi boyutta render edildiğine bakmaksızın 1080px çıktı üret.
    final displayWidth = boundary.size.width;
    final pixelRatio = displayWidth > 0 ? _targetPx / displayWidth : 2.0;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final bytes = byteData.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/$filePrefix${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    try {
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png'),
      ], text: text);
    } finally {
      // Paylaşım iletişim kutusu kapandıktan sonra geçici PNG'yi sil.
      // Hedef uygulama (WhatsApp/Twitter) dosya içeriğini zaten kendi
      // sandbox'ına kopyalamıştır; bizim temp'te tutmamızın yararı yok ve
      // finansal görseli diskte bırakmak KVKK Madde 12 minimizasyon
      // ilkesine aykırı. Silme başarısız olursa sessizce geç — startup
      // cleanup ikinci savunma hattı.
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {
        /* best-effort */
      }
    }
  }

  /// Uygulama açılışında çağrılır: 1 saatten eski `saydin_share_*.png`
  /// dosyalarını siler. Önceki oturumda paylaşım iletişim kutusu kapanmadan
  /// uygulama kapatılırsa [shareFromKey] finally bloğu çalışmaz — startup
  /// cleanup ikinci savunma hattıdır.
  ///
  /// Eşik 1 saat: bir paylaşım hedef uygulaması (WhatsApp vb.) henüz
  /// dosyayı tüketmediği için aktif iletişim kutusu kapanmadan bekleyen
  /// dosyaları kaçırırız. Pratikte share session 1 saatten uzun sürmez.
  static Future<void> cleanupStaleShareFiles({
    Duration olderThan = const Duration(hours: 1),
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;
      final cutoff = DateTime.now().subtract(olderThan);
      await for (final entry in tempDir.list(followLinks: false)) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.last;
        if (!name.startsWith(filePrefix) || !name.endsWith('.png')) continue;
        try {
          final stat = await entry.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entry.delete();
          }
        } catch (_) {
          /* best-effort per file */
        }
      }
    } catch (_) {
      /* best-effort overall */
    }
  }
}
