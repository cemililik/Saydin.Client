import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:share_plus/share_plus.dart';

/// Paylaşım kartı render edilemediğinde fırlatılır (F-05-22). Eskiden bu
/// durumlar sessizce `return` ediliyordu: kullanıcı "Paylaş"a basıyor, hiçbir
/// şey olmuyor ve neden olduğu hiçbir yere yazılmıyordu. Artık tipli hata
/// fırlatılır; çağıran katman kullanıcıya snackbar gösterir ve Sentry'ye
/// raporlar.
class ShareCardException implements Exception {
  /// Makine-okunur sebep (PII içermez — Sentry'ye güvenle gider):
  /// `boundary_null` (RepaintBoundary context'i yok) veya
  /// `encode_failed` (PNG byte kodlaması başarısız).
  final String reason;
  const ShareCardException(this.reason);

  @override
  String toString() => 'ShareCardException($reason)';
}

/// [RepaintBoundary] ile işaretlenmiş widget'ı PNG olarak yakalar ve
/// platform paylaşım sayfasını açar.
///
/// [shareText]: WhatsApp / Twitter gibi uygulamalarda görünecek metin.
/// Belirtilmezse varsayılan marka metni kullanılır.
///
/// Render başarısız olursa [ShareCardException] fırlatır — çağıran katman
/// yakalayıp kullanıcıya geri bildirir ve raporlar.
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
    // F-05-22: sessiz `return` yerine tipli hata — kullanıcı "Paylaş"a basıp
    // hiçbir şey olmaması + sebebin hiçbir yere yazılmaması durumunu kır.
    if (boundary == null) {
      throw const ShareCardException('boundary_null');
    }

    // Resolve l10n before async gap.
    final l10n = context.l10n;
    final text = (shareText ?? l10n.shareDefaultText) + l10n.shareCta;

    // Ekranda hangi boyutta render edildiğine bakmaksızın 1080px çıktı üret.
    final displayWidth = boundary.size.width;
    final pixelRatio = displayWidth > 0 ? _targetPx / displayWidth : 2.0;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw const ShareCardException('encode_failed');
    }

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
  ///
  /// [maxKept] LRU üst sınırıdır: 1 saatten yeni dosyalar bile bu sayıyı
  /// aşarsa en eski olanlar silinir. Kullanıcı kısa sürede çok sayıda
  /// paylaşım denerse veya force-quit ile finally bloğu kaçırırsa diskte
  /// finansal görsel birikimi engellenir (KVKK Madde 12 minimizasyon).
  static Future<void> cleanupStaleShareFiles({
    Duration olderThan = const Duration(hours: 1),
    int maxKept = 20,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) return;
      final cutoff = DateTime.now().subtract(olderThan);

      // İki geçiş: önce yaşa göre tara + sil, sonra LRU cap uygula.
      final survivors = <_DatedFile>[];
      await for (final entry in tempDir.list(followLinks: false)) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.last;
        if (!name.startsWith(filePrefix) || !name.endsWith('.png')) continue;
        try {
          final stat = await entry.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entry.delete();
          } else {
            survivors.add(_DatedFile(file: entry, modified: stat.modified));
          }
        } catch (_) {
          /* best-effort per file */
        }
      }

      if (survivors.length <= maxKept) return;

      survivors.sort((a, b) => a.modified.compareTo(b.modified));
      final toRemove = survivors.length - maxKept;
      for (var i = 0; i < toRemove; i++) {
        try {
          await survivors[i].file.delete();
        } catch (_) {
          /* best-effort */
        }
      }
    } catch (_) {
      /* best-effort overall */
    }
  }
}

class _DatedFile {
  final File file;
  final DateTime modified;
  const _DatedFile({required this.file, required this.modified});
}
