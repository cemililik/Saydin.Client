import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/theme/app_theme.dart';
import 'package:saydin/core/theme/theme_mode_mapper.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_event.dart';
import 'package:saydin/features/comparison/presentation/pages/comparison_page.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_bloc.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_event.dart';
import 'package:saydin/features/dca/presentation/pages/dca_page.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:saydin/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_event.dart';
import 'package:uuid/uuid.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:saydin/features/portfolio/presentation/pages/portfolio_page.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_state.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/presentation/pages/scenarios_page.dart';
import 'package:saydin/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_event.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_state.dart';
import 'package:saydin/features/what_if/presentation/pages/what_if_page.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class SaydinApp extends StatelessWidget {
  const SaydinApp({super.key});

  /// Kullanıcının dil tercihine göre locale döndürür.
  /// [AppLanguage.system] ise null döner — Flutter sistem diline göre seçer.
  static Locale? _resolveLocale(AppLanguage language) {
    return switch (language) {
      AppLanguage.tr => const Locale('tr', 'TR'),
      AppLanguage.en => const Locale('en', 'US'),
      AppLanguage.system => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<SettingsCubit>()..load()),
        BlocProvider(create: (_) => sl<FavoritesCubit>()..load()),
      ],
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, settings) {
          return MaterialApp(
            title: 'Saydın',
            debugShowCheckedModeBanner: false,
            locale: _resolveLocale(settings.language),
            supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: toFlutterThemeMode(settings.themeMode),
            home: MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<AppConfigCubit>()..load()),
                BlocProvider(create: (_) => sl<WhatIfBloc>()),
                BlocProvider(create: (_) => sl<ScenariosBloc>()),
                BlocProvider(create: (_) => sl<ComparisonBloc>()),
                BlocProvider(create: (_) => sl<PortfolioBloc>()),
                BlocProvider(create: (_) => sl<DcaBloc>()),
              ],
              child: const _AppHome(),
            ),
          );
        },
      ),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final repo = sl<OnboardingRepository>();
    final completed = await repo.isOnboardingCompleted();
    if (mounted) setState(() => _onboardingCompleted = completed);
  }

  Future<void> _completeOnboarding() async {
    await sl<OnboardingRepository>().completeOnboarding();
    if (mounted) setState(() => _onboardingCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingCompleted == null) {
      // Henüz yükleniyor
      return const Scaffold(body: SizedBox.shrink());
    }
    if (_onboardingCompleted == false) {
      return OnboardingPage(onComplete: _completeOnboarding);
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  AppLanguage? _previousLanguage;

  void _onScenarioTap(SavedScenario scenario) {
    switch (scenario.type) {
      case ScenarioType.whatIf:
        final isReverse = scenario.extraData?['mode'] == 'reverse';
        context.read<WhatIfBloc>().add(
          WhatIfReplayRequested(
            assetSymbol: scenario.assetSymbol,
            buyDate: scenario.buyDate,
            sellDate: scenario.sellDate,
            amount: scenario.amount,
            amountType: scenario.amountType,
            includeInflation:
                (scenario.extraData?['includeInflation'] as bool?) ?? false,
            calculationMode: isReverse
                ? CalculationMode.reverse
                : CalculationMode.normal,
          ),
        );
        setState(() => _selectedIndex = 0); // WhatIfPage
      case ScenarioType.comparison:
        context.read<ComparisonBloc>().add(
          ComparisonReplayRequested(
            symbols: scenario.assetSymbol.split(','),
            buyDate: scenario.buyDate,
            sellDate: scenario.sellDate,
            amount: scenario.amount,
            includeInflation:
                (scenario.extraData?['includeInflation'] as bool?) ?? false,
          ),
        );
        setState(() => _selectedIndex = 1);
      case ScenarioType.portfolio:
        const uuid = Uuid();
        final extraData = scenario.extraData;
        final rawItems = extraData?['items'] as List<dynamic>? ?? [];
        final items = rawItems.map((e) {
          final map = e as Map<String, dynamic>;
          return PortfolioItem(
            id: uuid.v4(),
            assetSymbol: map['assetSymbol'] as String,
            assetDisplayName: map['assetDisplayName'] as String,
            amount: map['amount'] as num,
            amountType: map['amountType'] as String,
          );
        }).toList();
        context.read<PortfolioBloc>().add(
          PortfolioReplayRequested(
            buyDate: scenario.buyDate,
            sellDate: scenario.sellDate,
            includeInflation:
                (extraData?['includeInflation'] as bool?) ?? false,
            items: items,
          ),
        );
        setState(() => _selectedIndex = 2);
      case ScenarioType.dca:
        final extra = scenario.extraData;
        context.read<DcaBloc>().add(
          DcaReplayRequested(
            assetSymbol: scenario.assetSymbol,
            startDate: scenario.buyDate,
            endDate: scenario.sellDate,
            periodicAmount:
                (extra?['periodicAmount'] as num?) ?? scenario.amount,
            period: (extra?['period'] as String?) ?? 'monthly',
            amountType: scenario.amountType,
            includeInflation: (extra?['includeInflation'] as bool?) ?? false,
          ),
        );
        setState(() => _selectedIndex = 3); // DcaPage
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsCubit, AppSettings>(
          listenWhen: (prev, curr) {
            final changed =
                _previousLanguage != null && _previousLanguage != curr.language;
            _previousLanguage = curr.language;
            return changed;
          },
          listener: (ctx, _) {
            // Dil değişti — form state'i koruyarak asset listesini yenile.
            ctx.read<WhatIfBloc>().add(const WhatIfLanguageChanged());
            ctx.read<ComparisonBloc>().add(const ComparisonLanguageChanged());
            ctx.read<PortfolioBloc>().add(const PortfolioLanguageChanged());
            ctx.read<DcaBloc>().add(const DcaLanguageChanged());
          },
        ),
        BlocListener<ScenariosBloc, ScenariosState>(
          listenWhen: (_, curr) =>
              curr is ScenariosSaved || curr is ScenariosDuplicate,
          listener: (ctx, state) {
            if (state is ScenariosSaved) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(ctx.l10n.scenarioSaved),
                  backgroundColor: AppColors.profit,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is ScenariosDuplicate) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(ctx.l10n.scenarioDuplicate),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const WhatIfPage(), // 0 — Hesaplama
            const ComparisonPage(), // 1 — Karşılaştırma
            const PortfolioPage(), // 2 — Portföy
            const DcaPage(), // 3 — DCA
            ScenariosPage(onScenarioTap: _onScenarioTap), // 4 — Senaryolar
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.calculate_outlined),
              activeIcon: const Icon(Icons.calculate),
              label: l10n.tabCalculate,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.compare_arrows_outlined),
              activeIcon: const Icon(Icons.compare_arrows),
              label: l10n.tabCompare,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: const Icon(Icons.account_balance_wallet),
              label: l10n.tabPortfolio,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.repeat_outlined),
              activeIcon: const Icon(Icons.repeat),
              label: l10n.tabDca,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bookmark_border),
              activeIcon: const Icon(Icons.bookmark),
              label: l10n.tabScenarios,
            ),
          ],
        ),
      ),
    );
  }
}
