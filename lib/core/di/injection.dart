import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/network/api_client.dart';
import 'package:saydin/features/comparison/data/repositories/comparison_repository_impl.dart';
import 'package:saydin/features/comparison/domain/repositories/comparison_repository.dart';
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/config/data/repositories/app_config_repository_impl.dart';
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/scenarios/data/repositories/scenarios_repository_impl.dart';
import 'package:saydin/features/scenarios/domain/repositories/scenarios_repository.dart';
import 'package:saydin/features/scenarios/domain/usecases/delete_scenario.dart';
import 'package:saydin/features/scenarios/domain/usecases/get_scenarios.dart';
import 'package:saydin/features/scenarios/domain/usecases/save_scenario.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:saydin/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:saydin/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:saydin/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:saydin/features/what_if/data/repositories/what_if_repository_impl.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';
import 'package:saydin/features/portfolio/domain/usecases/calculate_portfolio.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:saydin/features/dca/data/repositories/dca_repository_impl.dart';
import 'package:saydin/features/dca/domain/repositories/dca_repository.dart';
import 'package:saydin/features/dca/domain/usecases/calculate_dca.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_bloc.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_reverse_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/calculate_what_if.dart';
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // PackageInfo (async — uygulama başlangıcında bir kez çözümlenir)
  final packageInfo = await PackageInfo.fromPlatform();

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
    return ApiClient(baseUrl: baseUrl, packageInfo: packageInfo);
  });

  // Error handling
  sl.registerLazySingleton(() => const DioErrorMapper());
  sl.registerLazySingleton(() => const ErrorReporter());

  // Onboarding
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(SharedPreferencesAsync()),
  );

  // Settings
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(SharedPreferencesAsync()),
  );
  sl.registerLazySingleton(() => SettingsCubit(sl()));

  // Favorites
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(SharedPreferencesAsync()),
  );
  sl.registerLazySingleton(() => FavoritesCubit(sl()));

  // App Config
  sl.registerLazySingleton<AppConfigRepository>(
    () => AppConfigRepositoryImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton(() => AppConfigCubit(sl()));

  // Repositories
  sl.registerLazySingleton<WhatIfRepository>(
    () => WhatIfRepositoryImpl(sl<ApiClient>().dio),
  );

  // Use cases
  sl.registerLazySingleton(() => CalculateWhatIf(sl()));
  sl.registerLazySingleton(() => CalculateReverseWhatIf(sl()));
  sl.registerLazySingleton(() => GetAssets(sl()));
  sl.registerLazySingleton(() => CalculatePortfolio(sl()));

  // Comparison
  sl.registerLazySingleton<ComparisonRepository>(
    () => ComparisonRepositoryImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton(() => CompareWhatIf(sl()));

  // DCA
  sl.registerLazySingleton<DcaRepository>(
    () => DcaRepositoryImpl(sl<ApiClient>().dio),
  );
  sl.registerLazySingleton(() => CalculateDca(sl()));

  // BLoC (factory — her sayfa açılışında yeni instance)
  sl.registerFactory(
    () => WhatIfBloc(sl(), sl(), sl(), errorMapper: sl(), reporter: sl()),
  );
  sl.registerFactory(
    () => ComparisonBloc(sl(), sl(), errorMapper: sl(), reporter: sl()),
  );
  sl.registerFactory(
    () => PortfolioBloc(sl(), sl(), errorMapper: sl(), reporter: sl()),
  );
  sl.registerFactory(
    () => DcaBloc(sl(), sl(), errorMapper: sl(), reporter: sl()),
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
