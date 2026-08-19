import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/core/network/device_id_interceptor.dart';
import 'package:saydin/core/storage/share_card_cache.dart';
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';

class AccountDataRepositoryImpl implements AccountDataRepository {
  static const _localCleanupMarkerName =
      'saydin_account_deletion_cleanup_pending_v1';

  AccountDataRepositoryImpl({
    required SharedPreferencesAsync prefs,
    required FlutterSecureStorage secureStorage,
    required Dio dio,
    required DeviceIdInterceptor deviceIdInterceptor,
    Future<Directory> Function()? temporaryDirectoryProvider,
    Future<Directory> Function()? deletionStateDirectoryProvider,
    bool? cleanupAndroidPluginCache,
  }) : _prefs = prefs,
       _secureStorage = secureStorage,
       _dio = dio,
       _deviceIdInterceptor = deviceIdInterceptor,
       _temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory,
       _deletionStateDirectoryProvider =
           deletionStateDirectoryProvider ?? getApplicationSupportDirectory,
       _cleanupAndroidPluginCache =
           cleanupAndroidPluginCache ?? Platform.isAndroid;

  final SharedPreferencesAsync _prefs;
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;
  final DeviceIdInterceptor _deviceIdInterceptor;
  final Future<Directory> Function() _temporaryDirectoryProvider;
  final Future<Directory> Function() _deletionStateDirectoryProvider;
  final bool _cleanupAndroidPluginCache;

  Future<File> _localCleanupMarker() async {
    // OS tarafından purge edilebilen temporary/cache dizini kullanılmaz.
    // Marker, cleanup tamamlanana kadar application-support alanında kalır.
    final directory = await _deletionStateDirectoryProvider();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}/$_localCleanupMarkerName');
  }

  @override
  Future<void> markLocalCleanupPending() async {
    final marker = await _localCleanupMarker();
    await marker.writeAsString('backend-confirmed-v1\n', flush: true);
  }

  @override
  Future<bool> hasPendingLocalCleanup() async {
    final marker = await _localCleanupMarker();
    // İçerik yarım kalmış olsa bile dosyanın varlığı backend-confirmed yazma
    // fazının başladığını gösterir. Fail-safe seçim backend DELETE'i tekrar
    // etmek yerine idempotent local cleanup'ı sürdürmektir.
    return marker.exists();
  }

  @override
  Future<void> clearPendingLocalCleanup() async {
    final marker = await _localCleanupMarker();
    if (await marker.exists()) await marker.delete();
  }

  /// Bilinmeyen depo başarısızlığını yutmamak için tek bir collector kullanıyoruz:
  /// SharedPreferences/SecureStorage/cache'in bir kısmı düşse bile diğer
  /// adımlar devam etmelidir. Tüm hatalar `AccountWipeException` ile fırlatılır.
  @override
  Future<void> wipeLocalData() async {
    final errors = <Object>[];

    try {
      await _prefs.clear();
    } catch (e) {
      errors.add(e);
    }

    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      errors.add(e);
    }

    try {
      await _wipeShareCardCache();
    } catch (e) {
      errors.add(e);
    }

    // In-memory cache'leri sıfırla — aynı oturumda eski device ID
    // kullanılmasını önler (KVKK Madde 11 ihlali).
    _deviceIdInterceptor.resetCache();

    if (errors.isNotEmpty) {
      throw AccountWipeException(errors);
    }
  }

  /// Uygulamanın `getTemporaryDirectory()/saydin_share_*.png` kaynaklarını ve
  /// Android'deki `cacheDir/share_plus/saydin_share_*.png` plugin kopyalarını
  /// siler. Paylaşım kartları finansal sonuç ekranının görsel kopyası olduğu
  /// için hesap silme tamamlandıktan sonra cihazda kalmamalıdır.
  ///
  /// "Attempt all deletes" politikası: bir dosya silinemese de geri kalanı
  /// silmeye devam edilir. Ancak son raporlama dürüst olmak zorunda — bir
  /// veya birden çok dosya başarısız olduysa toplu `AccountWipeException`
  /// fırlatılır ki `wipeLocalData` partial-failure'ı kullanıcıya bildirebilsin.
  Future<void> _wipeShareCardCache() async {
    final tempDir = await _temporaryDirectoryProvider();
    await ShareCardCache.wipeAll(
      temporaryDirectory: tempDir,
      includeAndroidPluginCache: _cleanupAndroidPluginCache,
    );
  }

  @override
  Future<bool> requestBackendDeletion() async {
    try {
      final response = await _dio.delete<void>(ApiEndpoints.account);
      final status = response.statusCode ?? 0;
      // Yalnız 200/204 → gerçekten silindi. 202 Accepted için silmenin son
      // durumunu doğrulayan ayrı bir endpoint olmadığından local wipe'a izin
      // vermeyiz. 404 ("endpoint yok / kullanıcı yok"), 501 ("not implemented")
      // veya başka durumlarda backend hiçbir
      // şey kaydetmediği için kullanıcıya "Success" demek KVKK Madde 7
      // ("silme talebi 30 gün içinde sonuçlandırılmalı") ile uyumsuz olur.
      // Kullanıcı PartialSuccess mesajı görmeli ve iletisim@saydin.app
      // üzerinden takip etmeli.
      return status == 200 || status == 204;
    } on DioException catch (e) {
      // Dio response döndüyse status'a bak (interceptor/non-2xx exception'a
      // çevirebilir). Yine yalnız 200/204 başarı sayılır.
      final status = e.response?.statusCode ?? 0;
      return status == 200 || status == 204;
    } catch (_) {
      return false;
    }
  }
}

/// `wipeLocalData` sırasında bir veya birden çok depo silinemediğinde fırlatılır.
class AccountWipeException implements Exception {
  AccountWipeException(this.causes);

  final List<Object> causes;

  @override
  String toString() => 'AccountWipeException(${causes.length} cause(s))';
}
