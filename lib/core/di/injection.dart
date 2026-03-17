import 'package:get_it/get_it.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/network/api_client.dart';
import 'package:saydin/features/comparison/data/repositories/comparison_repository_impl.dart';
import 'package:saydin/features/comparison/domain/repositories/comparison_repository.dart';
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/scenarios/data/repositories/scenarios_repository_impl.dart';
import 'package:saydin/features/scenarios/domain/repositories/scenarios_repository.dart';
import 'package:saydin/features/scenarios/domain/usecases/delete_scenario.dart';
import 'package:saydin/features/scenarios/domain/usecases/get_scenarios.dart';
import 'package:saydin/features/scenarios/domain/usecases/save_scenario.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
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

  // Comparison
  sl.registerLazySingleton<ComparisonRepository>(
    () => ComparisonRepositoryImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton(() => CompareWhatIf(sl()));

  // BLoC (factory — her sayfa açılışında yeni instance)
  sl.registerFactory(
    () => WhatIfBloc(sl(), sl(), errorMapper: sl(), reporter: sl()),
  );
  sl.registerFactory(
    () => ComparisonBloc(sl(), sl(), errorMapper: sl(), reporter: sl()),
  );

  // Scenarios
  sl.registerLazySingleton<ScenariosRepository>(
    () => ScenariosRepositoryImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton(() => GetScenarios(sl()));
  sl.registerLazySingleton(() => SaveScenario(sl()));
  sl.registerLazySingleton(() => DeleteScenario(sl()));
  sl.registerFactory(
    () => ScenariosBloc(sl(), sl(), sl(), errorMapper: sl(), reporter: sl()),
  );
}
