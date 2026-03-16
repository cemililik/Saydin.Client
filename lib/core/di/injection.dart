import 'package:get_it/get_it.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/network/api_client.dart';
import 'package:saydin/features/what_if/data/repositories/what_if_repository_impl.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart';

final sl = GetIt.instance;

void configureDependencies() {
  // Network
  sl.registerLazySingleton<ApiClient>(() {
    const baseUrl = String.fromEnvironment('API_BASE_URL');
    assert(
      baseUrl.isNotEmpty,
      'API_BASE_URL dart-define is required. '
      'Pass --dart-define=API_BASE_URL=http://<host>:5080',
    );
    if (baseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL dart-define is required. '
        'Pass --dart-define=API_BASE_URL=http://<host>:5080',
      );
    }
    return ApiClient(baseUrl: baseUrl);
  });

  // Error handling
  sl.registerLazySingleton(() => const DioErrorMapper());
  sl.registerLazySingleton(() => const ErrorReporter());

  // Repositories
  sl.registerLazySingleton<WhatIfRepository>(
    () => WhatIfRepositoryImpl(sl<ApiClient>().dio),
  );

  // Use cases
  sl.registerLazySingleton(() => CalculateWhatIf(sl()));
  sl.registerLazySingleton(() => GetAssets(sl()));

  // BLoC (factory — her sayfa açılışında yeni instance)
  sl.registerFactory(
    () => WhatIfBloc(sl(), sl(), errorMapper: sl(), reporter: sl()),
  );
}
