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
      '${tempDir.path}/saydin_share_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([
      XFile(file.path, mimeType: 'image/png'),
    ], text: text);
  }
}
