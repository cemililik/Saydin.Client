import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saydin/core/network/device_id_interceptor.dart';
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';

class AccountDataRepositoryImpl implements AccountDataRepository {
  AccountDataRepositoryImpl({
    required SharedPreferencesAsync prefs,
    required FlutterSecureStorage secureStorage,
    required Dio dio,
    required DeviceIdInterceptor deviceIdInterceptor,
  }) : _prefs = prefs,
       _secureStorage = secureStorage,
       _dio = dio,
       _deviceIdInterceptor = deviceIdInterceptor;

  final SharedPreferencesAsync _prefs;
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;
  final DeviceIdInterceptor _deviceIdInterceptor;

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

  /// `ShareCardRenderer`'ın `getTemporaryDirectory()/saydin_share_*.png`
  /// dosyalarını siler. Paylaşım kartları finansal sonuç ekranının görsel
  /// kopyası olduğu için cihazda kalmamalıdır.
  ///
  /// "Attempt all deletes" politikası: bir dosya silinemese de geri kalanı
  /// silmeye devam edilir. Ancak son raporlama dürüst olmak zorunda — bir
  /// veya birden çok dosya başarısız olduysa toplu `AccountWipeException`
  /// fırlatılır ki `wipeLocalData` partial-failure'ı kullanıcıya bildirebilsin.
  Future<void> _wipeShareCardCache() async {
    final tempDir = await getTemporaryDirectory();
    if (!tempDir.existsSync()) return;
    final fileErrors = <Object>[];
    await for (final entry in tempDir.list(followLinks: false)) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      if (name.startsWith('saydin_share_') && name.endsWith('.png')) {
        try {
          await entry.delete();
        } catch (e) {
          fileErrors.add(e);
        }
      }
    }
    if (fileErrors.isNotEmpty) {
      throw AccountWipeException(fileErrors);
    }
  }

  @override
  Future<bool> requestBackendDeletion() async {
    try {
      final response = await _dio.delete<void>('/v1/account');
      final status = response.statusCode ?? 0;
      // Sadece 2xx → gerçekten silindi. 404 ("endpoint yok / kullanıcı yok"),
      // 501 ("not implemented") veya başka non-2xx durumlarda backend hiçbir
      // şey kaydetmediği için kullanıcıya "Success" demek KVKK Madde 7
      // ("silme talebi 30 gün içinde sonuçlandırılmalı") ile uyumsuz olur.
      // Kullanıcı PartialSuccess mesajı görmeli ve iletisim@saydin.app
      // üzerinden takip etmeli.
      return status >= 200 && status < 300;
    } on DioException catch (e) {
      // Dio response döndüyse status'a bak (interceptor/non-2xx exception'a
      // çevirebilir). Yine sadece 2xx başarı sayılır.
      final status = e.response?.statusCode ?? 0;
      return status >= 200 && status < 300;
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
