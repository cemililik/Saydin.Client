import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/network/device_id_interceptor.dart';
import 'package:saydin/features/account/data/repositories/account_data_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDio extends Mock implements Dio {}

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockDeviceIdInterceptor extends Mock implements DeviceIdInterceptor {}

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
  });

  /// Cubit ile entegrasyon: `wipeLocalData` ve `DeviceIdInterceptor.resetCache`
  /// SDK/IO bağımlılığı gerektirdiği için bu testler sadece
  /// `requestBackendDeletion`'a odaklanır. Geri kalan davranış cubit testinde
  /// fake'lerle simüle edilmiştir.
  group('AccountDataRepositoryImpl.requestBackendDeletion', () {
    AccountDataRepositoryImpl buildRepo() {
      // Sadece `_dio` kullanılan testlerde diğer bağımlılıklar `late`
      // alanlar olarak kalır. Kullanılmadıkları için runtime'da erişilmez.
      // Bu pattern'in kırılgan olduğunu kabul ediyoruz — gelecekte
      // `requestBackendDeletion`'ı ayrı bir sınıfa çıkartmak temiz olur.
      return _RepoUnderTest(dio: dio);
    }

    test('requestBackendDeletion_status200_returnsTrue', () async {
      when(() => dio.delete<void>(any())).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/v1/account'),
          statusCode: 200,
        ),
      );

      expect(await buildRepo().requestBackendDeletion(), isTrue);
    });

    test('requestBackendDeletion_status204_returnsTrue', () async {
      when(() => dio.delete<void>(any())).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/v1/account'),
          statusCode: 204,
        ),
      );

      expect(await buildRepo().requestBackendDeletion(), isTrue);
    });

    test('requestBackendDeletion_status404_returnsFalse', () async {
      // Önceki davranış: 404 → true ("endpoint hazır değil, yerel wipe yeter")
      // Yeni davranış: 404 → false (KVKK Madde 7 — backend kayıt yoksa
      // kullanıcıya 'Success' demek yanıltıcı; PartialSuccess gösterilmeli)
      when(() => dio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/account'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/v1/account'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(await buildRepo().requestBackendDeletion(), isFalse);
    });

    test('requestBackendDeletion_status501_returnsFalse', () async {
      when(() => dio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/account'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/v1/account'),
            statusCode: 501,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(await buildRepo().requestBackendDeletion(), isFalse);
    });

    test('requestBackendDeletion_status500_returnsFalse', () async {
      when(() => dio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/account'),
          response: Response<void>(
            requestOptions: RequestOptions(path: '/v1/account'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(await buildRepo().requestBackendDeletion(), isFalse);
    });

    test('requestBackendDeletion_networkError_returnsFalse', () async {
      when(() => dio.delete<void>(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/account'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(await buildRepo().requestBackendDeletion(), isFalse);
    });
  });
}

/// Test-only alt sınıf: `requestBackendDeletion` sadece `_dio` kullanır,
/// diğer bağımlılıklar (`SharedPreferencesAsync`, `FlutterSecureStorage`,
/// `DeviceIdInterceptor`) bu testlerde erişilmediği için noop mock olarak
/// geçirilir. Entegrasyon davranışı `AccountDeletionCubitTest`'te kapsanır.
class _RepoUnderTest extends AccountDataRepositoryImpl {
  _RepoUnderTest({required super.dio})
    : super(
        prefs: _MockPrefs(),
        secureStorage: _MockSecureStorage(),
        deviceIdInterceptor: _MockDeviceIdInterceptor(),
      );
}
