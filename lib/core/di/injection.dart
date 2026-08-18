import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saydin/core/error/dio_error_mapper.dart';
import 'package:saydin/core/storage/secure_storage_factory.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/core/network/api_base_url_validator.dart';
import 'package:saydin/core/network/api_client.dart';
import 'package:saydin/core/network/locale_provider.dart';
import 'package:saydin/core/platform/platform_info.dart';
import 'package:saydin/features/account/data/repositories/account_data_repository_impl.dart';
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_cubit.dart';
import 'package:saydin/features/legal/data/repositories/legal_repository_impl.dart';
import 'package:saydin/features/legal/domain/repositories/legal_repository.dart';
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
import 'package:saydin/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:saydin/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:saydin/features/settings/domain/usecases/reset_local_preferences.dart';
import 'package:saydin/features/what_if/data/repositories/what_if_repository_impl.dart';
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart';
import 'package:saydin/features/portfolio/data/repositories/portfolio_repository_impl.dart';
import 'package:saydin/features/portfolio/domain/repositories/portfolio_repository.dart';
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

Future<void> configureDependencies({
  @visibleForTesting String? apiBaseUrlOverride,
}) async {
  // Ağ bağımlılığı lazy singleton olsa bile base URL hatası lazy olmamalı:
  // uygulama açılışında, hiçbir request/device identifier payload'ı
  // gönderilmeden fail-loud olur (SEC-08).
  const configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  final apiBaseUrl = apiBaseUrlOverride ?? configuredApiBaseUrl;
  ApiBaseUrlValidator.validate(apiBaseUrl);

  // PackageInfo (async — uygulama başlangıcında bir kez çözümlenir).
  // Singleton olarak kaydedilir: hem network katmanı hem de Sentry cihaz
  // scope'u (F-05-07) aynı instance'ı paylaşır.
  final packageInfo = await PackageInfo.fromPlatform();
  sl.registerSingleton<PackageInfo>(packageInfo);

  // Platform & locale soyutlamaları — network katmanı dart:io/global state'e
  // sızmasın diye DI ile enjekte edilir (F-05-06, F-12-17). Tek instance:
  // LanguageInterceptor okur, SettingsCubit aynı LocaleProvider'ı günceller.
  sl.registerLazySingleton<PlatformInfo>(SystemPlatformInfo.new);
  sl.registerLazySingleton<LocaleProvider>(AppLocaleHolder.new);

  // Network
  sl.registerLazySingleton<ApiClient>(() {
    return ApiClient(
      baseUrl: apiBaseUrl,
      packageInfo: packageInfo,
      platformInfo: sl<PlatformInfo>(),
      localeProvider: sl<LocaleProvider>(),
    );
  });

  // Error handling
  sl.registerLazySingleton(() => const DioErrorMapper());
  sl.registerLazySingleton(() => const ErrorReporter());

  // Lifecycle events (cross-feature publish/subscribe: hesap silme → reset)
  sl.registerLazySingleton(AppLifecycleEvents.new);

  // Onboarding
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(SharedPreferencesAsync()),
  );

  // Settings
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(SharedPreferencesAsync()),
  );

  // Legal — statik içerik, network çağrısı yok
  sl.registerLazySingleton<LegalRepository>(() => const LegalRepositoryImpl());

  // Account (KVKK Madde 11 / GDPR Madde 17 — hesap silme)
  sl.registerLazySingleton<AccountDataRepository>(
    () => AccountDataRepositoryImpl(
      prefs: SharedPreferencesAsync(),
      secureStorage: SecureStorageFactory.create(),
      dio: sl<ApiClient>().dio,
      deviceIdInterceptor: sl<ApiClient>().deviceIdInterceptor,
    ),
  );
  sl.registerFactory(
    () => AccountDeletionCubit(
      repository: sl(),
      reporter: sl(),
      lifecycleEvents: sl(),
    ),
  );

  // Favorites
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(SharedPreferencesAsync()),
  );
  sl.registerLazySingleton(
    () => ResetLocalPreferences(
      sl<SettingsRepository>(),
      sl<FavoritesRepository>(),
      sl<OnboardingRepository>(),
    ),
  );

  // App Config
  sl.registerLazySingleton<AppConfigRepository>(
    () => AppConfigRepositoryImpl(sl<ApiClient>().dio),
  );
  registerSessionCubitFactories(sl);

  // Repositories — DioErrorMapper repo katmanına enjekte edilir; BLoC'lar
  // yalnızca AppError görür (F-07-02/F-08-17/F-10-12; Dio sızıntısı kapatıldı).
  sl.registerLazySingleton<WhatIfRepository>(
    () => WhatIfRepositoryImpl(sl<ApiClient>().dio, sl<DioErrorMapper>()),
  );

  // Use cases
  sl.registerLazySingleton(() => CalculateWhatIf(sl()));
  sl.registerLazySingleton(() => CalculateReverseWhatIf(sl()));
  sl.registerLazySingleton(() => GetAssets(sl(), sl<LocaleProvider>()));

  // Portfolio — kendi data katmanı (F-09-01); hesaplamayı WhatIfRepository'ye
  // delege eder ve WhatIfResult'ı portföye ait PortfolioCalculation'a map'ler.
  sl.registerLazySingleton<PortfolioRepository>(
    () => PortfolioRepositoryImpl(
      sl<WhatIfRepository>(),
      reporter: sl<ErrorReporter>(),
    ),
  );
  sl.registerLazySingleton(() => CalculatePortfolio(sl<PortfolioRepository>()));

  // Comparison
  sl.registerLazySingleton<ComparisonRepository>(
    () => ComparisonRepositoryImpl(sl<ApiClient>().dio, sl<DioErrorMapper>()),
  );
  sl.registerLazySingleton(() => CompareWhatIf(sl()));

  // DCA
  sl.registerLazySingleton<DcaRepository>(
    () => DcaRepositoryImpl(sl<ApiClient>().dio, sl<DioErrorMapper>()),
  );
  sl.registerLazySingleton(() => CalculateDca(sl()));

  // BLoC (factory — her sayfa açılışında yeni instance). Hata eşleme
  // repository katmanında yapıldığı için BLoC'lara DioErrorMapper geçilmez.
  sl.registerFactory(() => WhatIfBloc(sl(), sl(), sl(), reporter: sl()));
  sl.registerFactory(() => ComparisonBloc(sl(), sl(), reporter: sl()));
  sl.registerFactory(() => PortfolioBloc(sl(), sl(), reporter: sl()));
  sl.registerFactory(() => DcaBloc(sl(), sl(), reporter: sl()));

  // Scenarios
  sl.registerLazySingleton<ScenariosRepository>(
    () => ScenariosRepositoryImpl(
      sl<ApiClient>().dio,
      errorMapper: sl<DioErrorMapper>(),
    ),
  );
  sl.registerLazySingleton(() => GetScenarios(sl()));
  sl.registerLazySingleton(() => SaveScenario(sl()));
  sl.registerLazySingleton(() => DeleteScenario(sl()));
  sl.registerFactory(() => ScenariosBloc(sl(), sl(), sl(), reporter: sl()));
}

/// Root [BlocProvider] ağacının sahip olduğu session cubit'leri factory olmak
/// zorundadır. Hesap silme resetinde provider'lar eski instance'ları kapatır;
/// lazy singleton kullanılırsa GetIt aynı kapalı instance'ı yeni ağaca verirdi.
@visibleForTesting
void registerSessionCubitFactories(GetIt locator) {
  locator.registerFactory(
    () => OnboardingCubit(
      locator<OnboardingRepository>(),
      reporter: locator<ErrorReporter>(),
    ),
  );
  locator.registerFactory(
    () => SettingsCubit(
      locator<SettingsRepository>(),
      locator<LocaleProvider>(),
      reporter: locator<ErrorReporter>(),
    ),
  );
  locator.registerFactory(
    () => FavoritesCubit(
      locator<FavoritesRepository>(),
      reporter: locator<ErrorReporter>(),
    ),
  );
  locator.registerFactory(
    () => AppConfigCubit(
      locator<AppConfigRepository>(),
      reporter: locator<ErrorReporter>(),
    ),
  );
}
