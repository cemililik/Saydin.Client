import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/share_card_renderer.dart';

void main() {
  test('PNG encoding disposes the native image', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 4, 4),
      ui.Paint()..color = const ui.Color(0xFF1565C0),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(4, 4);
    picture.dispose();

    final png = await ShareCardRenderer.encodePngAndDispose(image);

    expect(png, isNotNull);
    expect(image.debugDisposed, isTrue);
  });
}
