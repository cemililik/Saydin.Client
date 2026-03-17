import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/comparison/presentation/pages/comparison_page.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/presentation/pages/scenarios_page.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_event.dart';
import 'package:saydin/features/what_if/presentation/pages/what_if_page.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class SaydinApp extends StatelessWidget {
  const SaydinApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<AppConfigCubit>()..load()),
          BlocProvider(create: (_) => sl<WhatIfBloc>()),
          BlocProvider(create: (_) => sl<ScenariosBloc>()),
          BlocProvider(create: (_) => sl<ComparisonBloc>()),
        ],
        child: const MainShell(),
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
    context.read<WhatIfBloc>().add(
      WhatIfReplayRequested(
        assetSymbol: scenario.assetSymbol,
        buyDate: scenario.buyDate,
        sellDate: scenario.sellDate,
        amount: scenario.amount,
        amountType: scenario.amountType,
      ),
    );
    setState(() => _selectedIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const WhatIfPage(),
          ScenariosPage(onScenarioTap: _onScenarioTap),
          const ComparisonPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.calculate_outlined),
            activeIcon: const Icon(Icons.calculate),
            label: l10n.tabCalculate,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_border),
            activeIcon: const Icon(Icons.bookmark),
            label: l10n.tabScenarios,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.compare_arrows_outlined),
            activeIcon: const Icon(Icons.compare_arrows),
            label: l10n.tabCompare,
          ),
        ],
      ),
    );
  }
}
