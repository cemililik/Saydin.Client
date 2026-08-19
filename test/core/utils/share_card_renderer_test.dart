import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/share_card_renderer.dart';

class _RecordingShareGateway implements ShareGateway {
  final ShareGatewayResult result;
  int invocationCount = 0;
  String? filePath;
  String? mimeType;
  String? text;
  Rect? origin;

  _RecordingShareGateway({this.result = ShareGatewayResult.dismissed});

  @override
  Future<ShareGatewayResult> shareFile({
    required String filePath,
    required String mimeType,
    required String text,
    required Rect sharePositionOrigin,
  }) async {
    invocationCount++;
    this.filePath = filePath;
    this.mimeType = mimeType;
    this.text = text;
    origin = sharePositionOrigin;
    return result;
  }
}

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

  group('share position origin validation', () {
    const viewport = Rect.fromLTWH(0, 0, 800, 600);

    test('accepts a finite non-empty rect on the visible surface', () {
      const origin = Rect.fromLTWH(24, 500, 752, 48);

      expect(
        ShareCardRenderer.validatedSharePositionOrigin(
          origin,
          viewport: viewport,
        ),
        origin,
      );
    });

    test('rejects null empty non-finite and offscreen origins', () {
      final invalidOrigins = <Rect?>[
        null,
        Rect.zero,
        const Rect.fromLTWH(double.nan, 0, 10, 10),
        const Rect.fromLTWH(900, 700, 10, 10),
      ];

      for (final origin in invalidOrigins) {
        expect(
          () => ShareCardRenderer.validatedSharePositionOrigin(
            origin,
            viewport: viewport,
          ),
          throwsA(
            isA<ShareCardException>().having(
              (error) => error.reason,
              'reason',
              'share_origin_invalid',
            ),
          ),
        );
      }
    });
  });

  test(
    'renderer forwards the exact caption through the gateway seam',
    () async {
      final gateway = _RecordingShareGateway();
      const origin = Rect.fromLTWH(20, 500, 300, 48);
      const caption = '  Paylaşım\nmetni + CTA  ';

      final result = await ShareCardRenderer.distributeShareFile(
        filePath: '/verified/cache/saydin_share_result.png',
        mimeType: 'image/png',
        caption: caption,
        sharePositionOrigin: origin,
        gateway: gateway,
        canExecuteShare: () => true,
      );

      expect(result, ShareDeliveryResult.dismissed);
      expect(gateway.filePath, '/verified/cache/saydin_share_result.png');
      expect(gateway.mimeType, 'image/png');
      expect(gateway.origin, origin);
      expect(gateway.text, caption);
      expect(gateway.text!.codeUnits, caption.codeUnits);
    },
  );

  test('gateway results map to plugin-independent delivery results', () async {
    const origin = Rect.fromLTWH(20, 500, 300, 48);
    final cases = <ShareGatewayResult, ShareDeliveryResult>{
      ShareGatewayResult.success: ShareDeliveryResult.completed,
      ShareGatewayResult.dismissed: ShareDeliveryResult.dismissed,
      ShareGatewayResult.unavailable: ShareDeliveryResult.unavailable,
    };

    for (final entry in cases.entries) {
      final result = await ShareCardRenderer.distributeShareFile(
        filePath: '/verified/cache/saydin_share_result.png',
        mimeType: 'image/png',
        caption: 'caption',
        sharePositionOrigin: origin,
        gateway: _RecordingShareGateway(result: entry.key),
        canExecuteShare: () => true,
      );

      expect(result, entry.value);
    }
  });

  test(
    'denied before start performs no render file or gateway action',
    () async {
      final gateway = _RecordingShareGateway();
      var temporaryDirectoryCalls = 0;

      final result = await ShareCardRenderer.shareFromKey(
        GlobalKey(),
        caption: 'caption',
        viewport: const Rect.fromLTWH(0, 0, 800, 600),
        sharePositionOrigin: const Rect.fromLTWH(20, 500, 300, 48),
        canExecuteShare: () => false,
        gateway: gateway,
        temporaryDirectoryProvider: () async {
          temporaryDirectoryCalls++;
          throw StateError('must not reach the file system');
        },
      );

      expect(result, ShareDeliveryResult.denied);
      expect(temporaryDirectoryCalls, 0);
      expect(gateway.invocationCount, 0);
    },
  );

  test(
    'denied before gateway deletes the rendered temp file and skips native UI',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'saydin-share-midflight-denied-',
      );
      addTearDown(() async {
        if (temporaryDirectory.existsSync()) {
          await temporaryDirectory.delete(recursive: true);
        }
      });
      final gateway = _RecordingShareGateway();

      final result = await ShareCardRenderer.deliverRenderedBytes(
        bytes: Uint8List.fromList([1, 2, 3]),
        caption: 'final caption',
        sharePositionOrigin: const Rect.fromLTWH(20, 500, 300, 48),
        canExecuteShare: () => false,
        gateway: gateway,
        temporaryDirectoryProvider: () async => temporaryDirectory,
      );

      expect(result, ShareDeliveryResult.denied);
      expect(gateway.invocationCount, 0);
      expect(
        temporaryDirectory
            .listSync(followLinks: false)
            .whereType<File>()
            .where(
              (file) => file.uri.pathSegments.last.startsWith(
                ShareCardRenderer.filePrefix,
              ),
            ),
        isEmpty,
      );
    },
  );

  test('startup wrapper includes the Android share_plus cache', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'saydin-share-startup-test-',
    );
    addTearDown(() async {
      if (temporaryDirectory.existsSync()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });
    final pluginDirectory = Directory('${temporaryDirectory.path}/share_plus');
    await pluginDirectory.create();
    final pluginCopy = File(
      '${pluginDirectory.path}/saydin_share_previous_session.png',
    );
    await pluginCopy.writeAsBytes([1, 2, 3]);

    await ShareCardRenderer.cleanupStaleShareFiles(
      olderThan: Duration.zero,
      includeAndroidPluginCache: true,
      temporaryDirectoryProvider: () async => temporaryDirectory,
    );

    expect(pluginCopy.existsSync(), isFalse);
  });
}
