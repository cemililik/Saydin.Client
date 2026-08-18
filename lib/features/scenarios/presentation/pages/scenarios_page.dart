import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error_messages.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/widgets/settings_icon_button.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_state.dart';
import 'package:saydin/features/scenarios/presentation/widgets/scenario_card.dart';

class _SwipeToDeleteCard extends StatefulWidget {
  final SavedScenario scenario;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _SwipeToDeleteCard({
    super.key,
    required this.scenario,
    required this.onDelete,
    this.onTap,
  });

  @override
  State<_SwipeToDeleteCard> createState() => _SwipeToDeleteCardState();
}

class _SwipeToDeleteCardState extends State<_SwipeToDeleteCard> {
  double _progress = 0.0;

  Future<bool> _confirmDelete() async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.scenarioDeleteConfirmTitle),
            content: Text(
              l10n.scenarioDeleteConfirmMessage(
                widget.scenario.assetDisplayName,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: Text(l10n.deleteScenario),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteFromButton() async {
    if (await _confirmDelete() && mounted) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.errorContainer.withValues(
      alpha: _progress,
    );
    final iconOpacity = (_progress * 1.5).clamp(0.0, 1.0);
    final iconScale = 0.6 + _progress * 0.4;

    return Row(
      children: [
        Expanded(
          child: Dismissible(
            key: ValueKey(widget.scenario.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(),
            onDismissed: (_) => widget.onDelete(),
            onUpdate: (details) {
              setState(() {
                _progress = details.reached ? 1.0 : details.progress;
              });
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Transform.scale(
                scale: iconScale,
                child: Opacity(
                  opacity: iconOpacity,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            child: ScenarioCard(scenario: widget.scenario, onTap: widget.onTap),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _deleteFromButton,
          tooltip: context.l10n.deleteScenario,
          color: theme.colorScheme.error,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}

class ScenariosPage extends StatefulWidget {
  final ValueChanged<SavedScenario>? onScenarioTap;

  const ScenariosPage({super.key, this.onScenarioTap});

  @override
  State<ScenariosPage> createState() => _ScenariosPageState();
}

class _ScenariosPageState extends State<ScenariosPage> {
  String? _requestedPlan;

  void _scheduleRequestForConfig(AppConfig config) {
    if (!config.isReady) return;
    final plan = config.tier.name;
    if (_requestedPlan == plan) return;
    _requestedPlan = plan;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requestedPlan != plan) return;
      context.read<ScenariosBloc>().add(ScenariosRequested(plan: plan));
    });
  }

  Future<void> _refresh() async {
    final config = context.read<AppConfigCubit>().state;
    if (!config.isReady) return;
    final completion = Completer<void>();
    context.read<ScenariosBloc>().add(
      ScenariosRequested(plan: config.tier.name, completion: completion),
    );
    await completion.future;
  }

  Future<void> _onDelete(SavedScenario scenario) async {
    final completion = Completer<bool>();
    context.read<ScenariosBloc>().add(
      ScenarioDeleteRequested(scenario.id, completion: completion),
    );
    final deleted = await completion.future;
    if (!mounted || !deleted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.scenarioDeleted),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final config = context.watch<AppConfigCubit>().state;
    _scheduleRequestForConfig(config);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scenariosTitle),
        centerTitle: true,
        actions: const [SettingsIconButton()],
      ),
      body: BlocConsumer<ScenariosBloc, ScenariosState>(
        listener: (context, state) {
          if (state is ScenariosFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error.localizedMessage(l10n)),
                backgroundColor: theme.colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (!config.isReady ||
              state is ScenariosInitial ||
              (state is ScenariosLoading && state.scenarios.isEmpty)) {
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
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.scenarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final scenario = state.scenarios[i];
                return _SwipeToDeleteCard(
                  key: ValueKey(scenario.id),
                  scenario: scenario,
                  onDelete: () => _onDelete(scenario),
                  onTap: widget.onScenarioTap != null
                      ? () => widget.onScenarioTap!(scenario)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
