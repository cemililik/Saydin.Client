import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/storage/share_card_cache.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'saydin-share-cache-test-',
    );
  });

  tearDown(() async {
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'startup retention cleans stale source and Android plugin copies',
    () async {
      final pluginDirectory = Directory(
        '${temporaryDirectory.path}/share_plus',
      );
      await pluginDirectory.create();

      final staleSource = File(
        '${temporaryDirectory.path}/saydin_share_stale.png',
      );
      final freshSource = File(
        '${temporaryDirectory.path}/saydin_share_fresh.png',
      );
      final stalePluginCopy = File(
        '${pluginDirectory.path}/saydin_share_stale.png',
      );
      final unrelatedPluginFile = File('${pluginDirectory.path}/other.png');
      for (final file in [
        staleSource,
        freshSource,
        stalePluginCopy,
        unrelatedPluginFile,
      ]) {
        await file.writeAsBytes([1]);
      }

      final now = DateTime(2026, 8, 19, 12);
      await staleSource.setLastModified(now.subtract(const Duration(hours: 2)));
      await stalePluginCopy.setLastModified(
        now.subtract(const Duration(hours: 2)),
      );
      await freshSource.setLastModified(
        now.subtract(const Duration(minutes: 5)),
      );

      await ShareCardCache.cleanupStale(
        temporaryDirectory: temporaryDirectory,
        includeAndroidPluginCache: true,
        olderThan: const Duration(hours: 1),
        now: now,
      );

      expect(staleSource.existsSync(), isFalse);
      expect(stalePluginCopy.existsSync(), isFalse);
      expect(freshSource.existsSync(), isTrue);
      expect(unrelatedPluginFile.existsSync(), isTrue);
    },
  );

  test(
    'account wipe deletes only exact Saydin PNG files in both roots',
    () async {
      final pluginDirectory = Directory(
        '${temporaryDirectory.path}/share_plus',
      );
      await pluginDirectory.create();

      final source = File('${temporaryDirectory.path}/saydin_share_source.png');
      final pluginCopy = File(
        '${pluginDirectory.path}/saydin_share_source.png',
      );
      final wrongExtension = File(
        '${temporaryDirectory.path}/saydin_share_source.txt',
      );
      final unrelatedPluginFile = File('${pluginDirectory.path}/other.png');
      for (final file in [
        source,
        pluginCopy,
        wrongExtension,
        unrelatedPluginFile,
      ]) {
        await file.writeAsBytes([1]);
      }

      await ShareCardCache.wipeAll(
        temporaryDirectory: temporaryDirectory,
        includeAndroidPluginCache: true,
      );

      expect(source.existsSync(), isFalse);
      expect(pluginCopy.existsSync(), isFalse);
      expect(wrongExtension.existsSync(), isTrue);
      expect(unrelatedPluginFile.existsSync(), isTrue);
      expect(pluginDirectory.existsSync(), isTrue);
    },
  );

  test(
    'account wipe rejects a symlinked plugin directory without traversal',
    () async {
      if (Platform.isWindows) return;

      final outsideDirectory = await Directory.systemTemp.createTemp(
        'saydin-share-cache-outside-',
      );
      addTearDown(() async {
        if (outsideDirectory.existsSync()) {
          await outsideDirectory.delete(recursive: true);
        }
      });
      final outsideShare = File(
        '${outsideDirectory.path}/saydin_share_private.png',
      );
      await outsideShare.writeAsBytes([1, 2, 3]);
      final pluginLink = Link('${temporaryDirectory.path}/share_plus');
      await pluginLink.create(outsideDirectory.path);

      await expectLater(
        ShareCardCache.wipeAll(
          temporaryDirectory: temporaryDirectory,
          includeAndroidPluginCache: true,
        ),
        throwsA(isA<ShareCardCacheCleanupException>()),
      );

      expect(outsideShare.existsSync(), isTrue);
      await pluginLink.delete();
    },
  );

  test(
    'account wipe rejects a symlinked matching file without traversal',
    () async {
      if (Platform.isWindows) return;

      final outsideDirectory = await Directory.systemTemp.createTemp(
        'saydin-share-cache-outside-file-',
      );
      final outsideFile = File('${outsideDirectory.path}/private.png');
      await outsideFile.writeAsBytes([1, 2, 3]);
      addTearDown(() async {
        if (outsideDirectory.existsSync()) {
          await outsideDirectory.delete(recursive: true);
        }
      });
      final shareLink = Link(
        '${temporaryDirectory.path}/saydin_share_escape.png',
      );
      await shareLink.create(outsideFile.path);

      await expectLater(
        ShareCardCache.wipeAll(temporaryDirectory: temporaryDirectory),
        throwsA(isA<ShareCardCacheCleanupException>()),
      );

      expect(outsideFile.existsSync(), isTrue);
      await shareLink.delete();
    },
  );
}
