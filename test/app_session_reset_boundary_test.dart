import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/app.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/core/network/locale_provider.dart';
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:saydin/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:saydin/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';

class _MockOnboardingRepository extends Mock implements OnboardingRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockFavoritesRepository extends Mock implements FavoritesRepository {}

class _MockAppConfigRepository extends Mock implements AppConfigRepository {}

class _MockLocaleProvider extends Mock implements LocaleProvider {}

void main() {
  testWidgets(
    'session reset bütün child state nesnelerini atomik yeniden yaratır',
    (tester) async {
      final events = AppLifecycleEvents();
      addTearDown(events.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AppSessionResetBoundary(
            lifecycleEvents: events,
            builder: (_) => const Row(
              children: [
                _SessionCounter(label: 'favorites'),
                _SessionCounter(label: 'financial-result'),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('favorites:0'));
      await tester.tap(find.text('financial-result:0'));
      await tester.pump();
      expect(find.text('favorites:1'), findsOneWidget);
      expect(find.text('financial-result:1'), findsOneWidget);

      events.requestReset();
      await tester.pump();

      expect(find.text('favorites:0'), findsOneWidget);
      expect(find.text('financial-result:0'), findsOneWidget);
      expect(find.text('favorites:1'), findsNothing);
      expect(find.text('financial-result:1'), findsNothing);
    },
  );

  testWidgets(
    'DI factory cubitleri provider resetinde kapalı instance olarak reuse edilmez',
    (tester) async {
      final locator = GetIt.asNewInstance();
      final events = AppLifecycleEvents();
      addTearDown(() async {
        await events.dispose();
        await locator.reset();
      });
      locator
        ..registerSingleton<OnboardingRepository>(_MockOnboardingRepository())
        ..registerSingleton<SettingsRepository>(_MockSettingsRepository())
        ..registerSingleton<FavoritesRepository>(_MockFavoritesRepository())
        ..registerSingleton<AppConfigRepository>(_MockAppConfigRepository())
        ..registerSingleton<LocaleProvider>(_MockLocaleProvider())
        ..registerSingleton<AppLifecycleEvents>(events)
        ..registerSingleton<ErrorReporter>(const ErrorReporter());
      registerSessionCubitFactories(locator);

      final generations = <List<dynamic>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AppSessionResetBoundary(
            lifecycleEvents: events,
            builder: (_) {
              final instances = <dynamic>[];
              generations.add(instances);
              return MultiBlocProvider(
                providers: [
                  BlocProvider<OnboardingCubit>(
                    lazy: false,
                    create: (_) {
                      final cubit = locator<OnboardingCubit>();
                      instances.add(cubit);
                      return cubit;
                    },
                  ),
                  BlocProvider<SettingsCubit>(
                    lazy: false,
                    create: (_) {
                      final cubit = locator<SettingsCubit>();
                      instances.add(cubit);
                      return cubit;
                    },
                  ),
                  BlocProvider<FavoritesCubit>(
                    lazy: false,
                    create: (_) {
                      final cubit = locator<FavoritesCubit>();
                      instances.add(cubit);
                      return cubit;
                    },
                  ),
                  BlocProvider<AppConfigCubit>(
                    lazy: false,
                    create: (_) {
                      final cubit = locator<AppConfigCubit>();
                      instances.add(cubit);
                      return cubit;
                    },
                  ),
                ],
                child: const SizedBox.shrink(),
              );
            },
          ),
        ),
      );

      events.requestReset();
      await tester.pump();

      expect(generations, hasLength(2));
      for (var index = 0; index < generations.first.length; index++) {
        expect(generations[0][index].isClosed, isTrue);
        expect(generations[1][index], isNot(same(generations[0][index])));
        expect(generations[1][index].isClosed, isFalse);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      for (final cubit in generations.last) {
        expect(cubit.isClosed, isTrue);
      }
    },
  );
}

class _SessionCounter extends StatefulWidget {
  const _SessionCounter({required this.label});

  final String label;

  @override
  State<_SessionCounter> createState() => _SessionCounterState();
}

class _SessionCounterState extends State<_SessionCounter> {
  var value = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => value++),
    child: Text('${widget.label}:$value'),
  );
}
