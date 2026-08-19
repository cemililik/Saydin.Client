import 'dart:io';

import 'package:flutter/foundation.dart';

/// Uygulamanın ürettiği paylaşım PNG'leri ile Android `share_plus` kopyalarını
/// aynı, dar kapsamlı saklama sözleşmesi altında yönetir.
///
/// Android'de `path_provider` geçici dizin olarak uygulamanın `cacheDir`'ini
/// döndürür. `share_plus 10.1.4` ise paylaşılacak dosyayı bunun doğrudan
/// altındaki `share_plus/` dizinine aynı dosya adıyla kopyalar. Bu sınıf başka
/// cache içeriklerine dokunmaz; yalnız [filePrefix] ile başlayan PNG'leri işler.
class ShareCardCache {
  ShareCardCache._();

  static const String filePrefix = 'saydin_share_';
  static const String _pluginDirectoryName = 'share_plus';

  /// Startup'ta çağrılan best-effort retention pass'i.
  ///
  /// Bir native hedefin halen dosyayı tüketiyor olabileceği pencereyi korumak
  /// için yalnız [olderThan]'dan eski dosyalar silinir. Kalan dosyalara ayrıca
  /// [maxKept] LRU üst sınırı uygulanır. Android'de aynı politika plugin-owned
  /// `cacheDir/share_plus` kopyalarına da uygulanır.
  static Future<void> cleanupStale({
    required Directory temporaryDirectory,
    Duration olderThan = const Duration(hours: 1),
    int maxKept = 20,
    bool includeAndroidPluginCache = false,
    @visibleForTesting DateTime? now,
  }) async {
    if (olderThan.isNegative) {
      throw ArgumentError.value(olderThan, 'olderThan', 'must not be negative');
    }
    if (maxKept < 0) {
      throw ArgumentError.value(maxKept, 'maxKept', 'must not be negative');
    }

    final errors = <Object>[];
    final canonicalRoot = await _canonicalDirectory(
      temporaryDirectory,
      errors: errors,
    );
    if (canonicalRoot == null) return;

    final cutoff = (now ?? DateTime.now()).subtract(olderThan);
    await _cleanupDirectory(
      canonicalRoot,
      cutoff: cutoff,
      maxKept: maxKept,
      deleteAll: false,
      errors: errors,
    );

    if (!includeAndroidPluginCache) return;
    final pluginDirectory = await _verifiedPluginDirectory(
      canonicalRoot,
      errors: errors,
    );
    if (pluginDirectory == null) return;
    await _cleanupDirectory(
      pluginDirectory,
      cutoff: cutoff,
      maxKept: maxKept,
      deleteAll: false,
      errors: errors,
    );

    // Startup cleanup bilinçli olarak best-effort'tur. Şüpheli path/symlink
    // veya tekil silme hatalarında dar kapsam korunur ve uygulama açılışı
    // bloke edilmez. Account wipe aynı primitive'i fail-visible kullanır.
  }

  /// Hesap silme akışında tüm Saydın paylaşım PNG'lerini fail-visible siler.
  ///
  /// `recursive: true` kullanılmaz. Root ve Android plugin dizini canonical
  /// olarak doğrulanır, symlink'ler takip edilmez ve yalnız doğrudan çocuk olan
  /// `saydin_share_*.png` dosyaları hedeflenir.
  static Future<void> wipeAll({
    required Directory temporaryDirectory,
    bool includeAndroidPluginCache = false,
  }) async {
    final errors = <Object>[];
    final canonicalRoot = await _canonicalDirectory(
      temporaryDirectory,
      errors: errors,
    );

    if (canonicalRoot != null) {
      await _cleanupDirectory(canonicalRoot, deleteAll: true, errors: errors);

      if (includeAndroidPluginCache) {
        final pluginDirectory = await _verifiedPluginDirectory(
          canonicalRoot,
          errors: errors,
        );
        if (pluginDirectory != null) {
          await _cleanupDirectory(
            pluginDirectory,
            deleteAll: true,
            errors: errors,
          );
        }
      }
    }

    if (errors.isNotEmpty) {
      throw ShareCardCacheCleanupException(List.unmodifiable(errors));
    }
  }

  static Future<Directory?> _canonicalDirectory(
    Directory directory, {
    required List<Object> errors,
  }) async {
    try {
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) return null;
      if (type != FileSystemEntityType.directory) {
        errors.add(
          FileSystemException(
            'Share cache root is not a physical directory',
            directory.path,
          ),
        );
        return null;
      }
      return Directory(await directory.resolveSymbolicLinks());
    } catch (error) {
      errors.add(error);
      return null;
    }
  }

  static Future<Directory?> _verifiedPluginDirectory(
    Directory canonicalRoot, {
    required List<Object> errors,
  }) async {
    final candidate = Directory(
      '${canonicalRoot.path}${Platform.pathSeparator}$_pluginDirectoryName',
    );
    try {
      final type = await FileSystemEntity.type(
        candidate.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) return null;
      if (type != FileSystemEntityType.directory) {
        errors.add(
          FileSystemException(
            'Android share_plus cache is not a physical directory',
            candidate.path,
          ),
        );
        return null;
      }

      final canonicalCandidate = Directory(
        await candidate.resolveSymbolicLinks(),
      );
      final expectedPath =
          '${canonicalRoot.path}${Platform.pathSeparator}$_pluginDirectoryName';
      if (canonicalCandidate.path != expectedPath) {
        errors.add(
          FileSystemException(
            'Android share_plus cache escaped the temporary directory',
            candidate.path,
          ),
        );
        return null;
      }
      return canonicalCandidate;
    } catch (error) {
      errors.add(error);
      return null;
    }
  }

  static Future<void> _cleanupDirectory(
    Directory canonicalDirectory, {
    DateTime? cutoff,
    int maxKept = 0,
    required bool deleteAll,
    required List<Object> errors,
  }) async {
    final survivors = <_DatedShareFile>[];
    try {
      await for (final entry in canonicalDirectory.list(followLinks: false)) {
        final name = entry.uri.pathSegments.last;
        if (!_isSharePng(name)) continue;

        try {
          final type = await FileSystemEntity.type(
            entry.path,
            followLinks: false,
          );
          if (type != FileSystemEntityType.file) {
            errors.add(
              FileSystemException(
                'Share artifact is not a physical file',
                entry.path,
              ),
            );
            continue;
          }

          final canonicalPath = await entry.resolveSymbolicLinks();
          final expectedPath =
              '${canonicalDirectory.path}${Platform.pathSeparator}$name';
          if (canonicalPath != expectedPath) {
            errors.add(
              FileSystemException(
                'Share artifact escaped its verified cache directory',
                entry.path,
              ),
            );
            continue;
          }

          final file = File(canonicalPath);
          if (deleteAll) {
            await file.delete();
            continue;
          }

          final stat = await file.stat();
          if (cutoff != null && stat.modified.isBefore(cutoff)) {
            await file.delete();
          } else {
            survivors.add(_DatedShareFile(file: file, modified: stat.modified));
          }
        } catch (error) {
          errors.add(error);
        }
      }
    } catch (error) {
      errors.add(error);
      return;
    }

    if (deleteAll || survivors.length <= maxKept) return;
    survivors.sort((a, b) => a.modified.compareTo(b.modified));
    final toRemove = survivors.length - maxKept;
    for (var index = 0; index < toRemove; index++) {
      try {
        await survivors[index].file.delete();
      } catch (error) {
        errors.add(error);
      }
    }
  }

  static bool _isSharePng(String name) =>
      name.startsWith(filePrefix) && name.endsWith('.png');
}

class ShareCardCacheCleanupException implements Exception {
  const ShareCardCacheCleanupException(this.causes);

  final List<Object> causes;

  @override
  String toString() =>
      'ShareCardCacheCleanupException(${causes.length} cause(s))';
}

class _DatedShareFile {
  const _DatedShareFile({required this.file, required this.modified});

  final File file;
  final DateTime modified;
}
