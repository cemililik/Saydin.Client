import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_state.dart';
import 'package:saydin/features/scenarios/presentation/widgets/scenario_card.dart';
import 'package:saydin/l10n/app_localizations.dart';

class ScenariosPage extends StatefulWidget {
  final ValueChanged<SavedScenario>? onScenarioTap;

  const ScenariosPage({super.key, this.onScenarioTap});

  @override
  State<ScenariosPage> createState() => _ScenariosPageState();
}

class _ScenariosPageState extends State<ScenariosPage> {
  @override
  void initState() {
    super.initState();
    context.read<ScenariosBloc>().add(const ScenariosRequested());
  }

  String _errorMessage(AppError error, AppLocalizations l10n) =>
      switch (error) {
        PriceNotFoundError() => l10n.errorPriceNotFound,
        DailyLimitError() => l10n.errorDailyLimit,
        ScenarioLimitError(:final limit) => l10n.errorScenarioLimit(limit),
        NoInternetError() => l10n.errorNoInternet,
        ServerError() => l10n.errorServer,
        UnknownError() => l10n.errorGeneric,
      };

  void _onDelete(BuildContext context, SavedScenario scenario) {
    final l10n = context.l10n;
    context.read<ScenariosBloc>().add(ScenarioDeleteRequested(scenario.id));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.scenarioDeleted),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scenariosTitle), centerTitle: true),
      body: BlocConsumer<ScenariosBloc, ScenariosState>(
        listener: (context, state) {
          if (state is ScenariosFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_errorMessage(state.error, l10n)),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ScenariosLoading && state.scenarios.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.scenarios.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 72,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.scenariosEmpty, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      l10n.scenariosEmptyHint,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ScenariosBloc>().add(const ScenariosRequested());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.scenarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final scenario = state.scenarios[i];
                return Dismissible(
                  key: ValueKey(scenario.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _onDelete(context, scenario),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  child: ScenarioCard(
                    scenario: scenario,
                    onTap: widget.onScenarioTap != null
                        ? () => widget.onScenarioTap!(scenario)
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
