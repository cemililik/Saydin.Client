import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/core/network/locale_provider.dart';
import 'package:saydin/core/widgets/settings_icon_button.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:saydin/l10n/app_localizations.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockLocaleProvider extends Mock implements LocaleProvider {}

void main() {
  setUpAll(() => registerFallbackValue(const AppSettings()));

  testWidgets('settings route updates the root SettingsCubit', (tester) async {
    final repository = _MockSettingsRepository();
    final localeProvider = _MockLocaleProvider();
    when(() => repository.save(any())).thenAnswer((_) async {});
    final cubit = SettingsCubit(repository, localeProvider);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: BlocBuilder<SettingsCubit, AppSettings>(
          builder: (context, settings) => MaterialApp(
            locale: switch (settings.language) {
              AppLanguage.tr => const Locale('tr'),
              AppLanguage.en => const Locale('en'),
              AppLanguage.system => const Locale('tr'),
            },
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: switch (settings.themeMode) {
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
              AppThemeMode.system => ThemeMode.system,
            },
            home: Scaffold(
              appBar: AppBar(actions: const [SettingsIconButton()]),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koyu'));
    await tester.pumpAndSettle();

    expect(cubit.state.themeMode, AppThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Tema'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(cubit.state.language, AppLanguage.en);
    expect(find.text('Theme'), findsOneWidget);
    verify(() => localeProvider.update('en')).called(1);
  });
}
