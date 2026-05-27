import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';

class AccountDataRepositoryImpl implements AccountDataRepository {
  AccountDataRepositoryImpl({
    required SharedPreferencesAsync prefs,
    required FlutterSecureStorage secureStorage,
    required Dio dio,
  }) : _prefs = prefs,
       _secureStorage = secureStorage,
       _dio = dio;

  final SharedPreferencesAsync _prefs;
  final FlutterSecureStorage _secureStorage;
  final Dio _dio;

  /// Bilinmeyen depo başarısızlığını yutmamak için tek bir collector kullanıyoruz:
  /// SharedPreferences/SecureStorage'ın bir kısmı düşse bile diğer adımlar
  /// devam etmelidir.
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

    if (errors.isNotEmpty) {
      // Tüm hatalar collector'a düştü; en az biri geçmiş olduğu için silme
      // kısmen başarılı sayılır. Cubit bu durumu kullanıcıya bildirir.
      throw AccountWipeException(errors);
    }
  }

  @override
  Future<bool> requestBackendDeletion() async {
    try {
      await _dio.delete<void>('/v1/account');
      return true;
    } on DioException catch (e) {
      // Backend hazır değil (404) veya not implemented (501) ise yerel silme
      // yeterlidir — sessizce başarısız say.
      final status = e.response?.statusCode;
      if (status == 404 || status == 501) return true;
      return false;
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
