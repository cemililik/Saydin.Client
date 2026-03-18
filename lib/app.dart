import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/theme/app_theme.dart';
import 'package:saydin/core/theme/theme_mode_mapper.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_event.dart';
import 'package:saydin/features/comparison/presentation/pages/comparison_page.dart';
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
import 'package:saydin/features/what_if/presentation/pages/what_if_page.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class SaydinApp extends StatelessWidget {
  const SaydinApp({super.key});

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
            locale: const Locale('tr', 'TR'),
            supportedLocales: const [Locale('tr', 'TR')],
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
              ],
              child: const MainShell(),
            ),
          );
        },
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onScenarioTap(SavedScenario scenario) {
    switch (scenario.type) {
      case ScenarioType.whatIf:
        context.read<WhatIfBloc>().add(
          WhatIfReplayRequested(
            assetSymbol: scenario.assetSymbol,
            buyDate: scenario.buyDate,
            sellDate: scenario.sellDate,
            amount: scenario.amount,
            amountType: scenario.amountType,
            includeInflation:
                (scenario.extraData?['includeInflation'] as bool?) ?? false,
          ),
        );
        setState(() => _selectedIndex = 0);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<ScenariosBloc, ScenariosState>(
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
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const WhatIfPage(), // 0 — Hesaplama
            const ComparisonPage(), // 1 — Karşılaştırma
            const PortfolioPage(), // 2 — Portföy
            ScenariosPage(onScenarioTap: _onScenarioTap), // 3 — Senaryolar
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
