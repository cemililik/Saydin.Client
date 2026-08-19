import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/network/device_id_interceptor.dart';
import 'package:saydin/core/constants/api_endpoints.dart';
import 'package:saydin/core/storage/share_card_cache.dart';
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
      verify(() => dio.delete<void>(ApiEndpoints.account)).called(1);
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

    test(
      'requestBackendDeletion_status202_returnsFalseUntilStatusIsVerifiable',
      () async {
        when(() => dio.delete<void>(any())).thenAnswer(
          (_) async => Response<void>(
            requestOptions: RequestOptions(path: '/v1/account'),
            statusCode: 202,
          ),
        );

        expect(await buildRepo().requestBackendDeletion(), isFalse);
      },
    );

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

  group('AccountDataRepositoryImpl.wipeLocalData', () {
    late _MockPrefs prefs;
    late _MockSecureStorage secureStorage;
    late _MockDeviceIdInterceptor deviceIdInterceptor;
    late Directory temporaryDirectory;

    setUp(() async {
      prefs = _MockPrefs();
      secureStorage = _MockSecureStorage();
      deviceIdInterceptor = _MockDeviceIdInterceptor();
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'saydin-account-wipe-test-',
      );
      when(() => prefs.clear()).thenAnswer((_) async {});
      when(() => secureStorage.deleteAll()).thenAnswer((_) async {});
    });

    tearDown(() async {
      if (temporaryDirectory.existsSync()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    AccountDataRepositoryImpl buildWipeRepo() => AccountDataRepositoryImpl(
      prefs: prefs,
      secureStorage: secureStorage,
      dio: dio,
      deviceIdInterceptor: deviceIdInterceptor,
      temporaryDirectoryProvider: () async => temporaryDirectory,
      deletionStateDirectoryProvider: () async => temporaryDirectory,
      cleanupAndroidPluginCache: true,
    );

    test(
      'backend-confirmed marker wipe boyunca kalır ve explicit clear ile silinir',
      () async {
        final repository = buildWipeRepo();

        expect(await repository.hasPendingLocalCleanup(), isFalse);
        await repository.markLocalCleanupPending();
        expect(await repository.hasPendingLocalCleanup(), isTrue);

        await repository.wipeLocalData();
        expect(
          await repository.hasPendingLocalCleanup(),
          isTrue,
          reason: 'Partial wipe sonrası process restart retry bilgisi kalmalı',
        );

        await repository.clearPendingLocalCleanup();
        expect(await repository.hasPendingLocalCleanup(), isFalse);
      },
    );

    test(
      'clears preferences secure storage share files and device id cache',
      () async {
        final sharePng = File(
          '${temporaryDirectory.path}/saydin_share_result.png',
        );
        final unrelatedPng = File('${temporaryDirectory.path}/other.png');
        final wrongExtension = File(
          '${temporaryDirectory.path}/saydin_share_result.txt',
        );
        final pluginCache = Directory('${temporaryDirectory.path}/share_plus');
        await pluginCache.create();
        final pluginSharePng = File(
          '${pluginCache.path}/saydin_share_result.png',
        );
        final pluginUnrelatedPng = File('${pluginCache.path}/other.png');
        await sharePng.writeAsBytes([1, 2, 3]);
        await unrelatedPng.writeAsBytes([4]);
        await wrongExtension.writeAsBytes([5]);
        await pluginSharePng.writeAsBytes([6, 7, 8]);
        await pluginUnrelatedPng.writeAsBytes([9]);

        await buildWipeRepo().wipeLocalData();

        verify(() => prefs.clear()).called(1);
        verify(() => secureStorage.deleteAll()).called(1);
        verify(() => deviceIdInterceptor.resetCache()).called(1);
        expect(sharePng.existsSync(), isFalse);
        expect(pluginSharePng.existsSync(), isFalse);
        expect(unrelatedPng.existsSync(), isTrue);
        expect(wrongExtension.existsSync(), isTrue);
        expect(pluginUnrelatedPng.existsSync(), isTrue);
      },
    );

    test('continues remaining cleanup and reports partial failure', () async {
      when(() => prefs.clear()).thenThrow(StateError('prefs unavailable'));
      final sharePng = File(
        '${temporaryDirectory.path}/saydin_share_partial.png',
      );
      await sharePng.writeAsBytes([1]);

      await expectLater(
        buildWipeRepo().wipeLocalData(),
        throwsA(
          isA<AccountWipeException>().having(
            (error) => error.causes,
            'causes',
            hasLength(1),
          ),
        ),
      );

      verify(() => prefs.clear()).called(1);
      verify(() => secureStorage.deleteAll()).called(1);
      verify(() => deviceIdInterceptor.resetCache()).called(1);
      expect(sharePng.existsSync(), isFalse);
    });

    test(
      'rejects a symlinked Android plugin cache and reports partial wipe',
      () async {
        if (Platform.isWindows) return;

        final outsideDirectory = await Directory.systemTemp.createTemp(
          'saydin-account-wipe-outside-',
        );
        final outsideShare = File(
          '${outsideDirectory.path}/saydin_share_private.png',
        );
        await outsideShare.writeAsBytes([1, 2, 3]);
        final pluginLink = Link('${temporaryDirectory.path}/share_plus');
        await pluginLink.create(outsideDirectory.path);
        addTearDown(() async {
          if (await pluginLink.exists()) await pluginLink.delete();
          if (outsideDirectory.existsSync()) {
            await outsideDirectory.delete(recursive: true);
          }
        });

        await expectLater(
          buildWipeRepo().wipeLocalData(),
          throwsA(
            isA<AccountWipeException>().having(
              (error) => error.causes.single,
              'share cleanup cause',
              isA<ShareCardCacheCleanupException>(),
            ),
          ),
        );

        verify(() => prefs.clear()).called(1);
        verify(() => secureStorage.deleteAll()).called(1);
        verify(() => deviceIdInterceptor.resetCache()).called(1);
        expect(outsideShare.existsSync(), isTrue);
        await pluginLink.delete();
      },
    );
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
