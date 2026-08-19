import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
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
  late final ValueNotifier<_SwipeDeleteVisual> _visual;
  bool _didTriggerThresholdHaptic = false;

  @override
  void initState() {
    super.initState();
    _visual = ValueNotifier(const _SwipeDeleteVisual());
  }

  @override
  void dispose() {
    _visual.dispose();
    super.dispose();
  }

  void _onSwipeUpdate(DismissUpdateDetails details) {
    final progress = details.progress.clamp(0.0, 1.0);
    _visual.value = _SwipeDeleteVisual(
      progress: progress,
      reached: details.reached,
    );

    if (details.reached && !_didTriggerThresholdHaptic) {
      _didTriggerThresholdHaptic = true;
      unawaited(HapticFeedback.selectionClick());
    } else if (progress < 0.01) {
      _didTriggerThresholdHaptic = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deleteAction = CustomSemanticsAction(
      label: context.l10n.deleteScenario,
    );
    return Semantics(
      key: ValueKey('scenario-delete-semantics-${widget.scenario.id}'),
      customSemanticsActions: {deleteAction: widget.onDelete},
      child: Dismissible(
        key: ValueKey(widget.scenario.id),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.32},
        movementDuration: const Duration(milliseconds: 180),
        resizeDuration: const Duration(milliseconds: 220),
        onDismissed: (_) => widget.onDelete(),
        onUpdate: _onSwipeUpdate,
        background: RepaintBoundary(
          child: ExcludeSemantics(
            child: _SwipeDeleteBackground(visual: _visual),
          ),
        ),
        child: RepaintBoundary(
          child: ScenarioCard(scenario: widget.scenario, onTap: widget.onTap),
        ),
      ),
    );
  }
}

class _SwipeDeleteVisual {
  const _SwipeDeleteVisual({this.progress = 0, this.reached = false});

  final double progress;
  final bool reached;
}

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground({required this.visual});

  final ValueListenable<_SwipeDeleteVisual> visual;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ValueListenableBuilder<_SwipeDeleteVisual>(
      valueListenable: visual,
      builder: (context, value, _) {
        final reveal = Curves.easeOutCubic.transform(value.progress);
        final foreground = value.reached
            ? colors.onError
            : colors.onErrorContainer;
        return Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Color.lerp(
              colors.errorContainer,
              colors.error,
              value.reached ? 0.85 : reveal * 0.25,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Transform.translate(
            offset: Offset(14 * (1 - reveal), 0),
            child: Opacity(
              opacity: reveal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.scenarioSwipeDeleteHint,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 120),
                    child: Icon(
                      value.reached
                          ? Icons.delete_forever_rounded
                          : Icons.delete_sweep_rounded,
                      key: ValueKey(value.reached),
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

const _scenarioUndoWindow = Duration(seconds: 5);

class _PendingScenarioDeletion {
  _PendingScenarioDeletion(this.scenario);

  final SavedScenario scenario;
  Timer? timer;
  bool committed = false;
}

class _ScenarioDeleteUndoContent extends StatefulWidget {
  const _ScenarioDeleteUndoContent({required this.onUndo});

  final VoidCallback onUndo;

  @override
  State<_ScenarioDeleteUndoContent> createState() =>
      _ScenarioDeleteUndoContentState();
}

class _ScenarioDeleteUndoContentState
    extends State<_ScenarioDeleteUndoContent> {
  var _secondsRemaining = _scenarioUndoWindow.inSeconds;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        return;
      }
      if (mounted) setState(() => _secondsRemaining--);
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(context.l10n.scenarioDeleted)),
        const SizedBox(width: 8),
        TextButton(
          onPressed: widget.onUndo,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          child: Text(context.l10n.scenarioUndoCountdown(_secondsRemaining)),
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
  final Set<String> _pendingDeleteIds = {};
  _PendingScenarioDeletion? _undoableDeletion;
  late ScenariosBloc _scenariosBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scenariosBloc = context.read<ScenariosBloc>();
  }

  @override
  void dispose() {
    // Sayfa 5 saniyelik pencere açıkken kapanırsa kullanıcının ekranda gördüğü
    // silme işlemini yarım bırakma. Root BLoC bu sayfadan daha uzun yaşar.
    final pending = _undoableDeletion;
    pending?.timer?.cancel();
    if (pending != null && !pending.committed && !_scenariosBloc.isClosed) {
      pending.committed = true;
      _scenariosBloc.add(ScenarioDeleteRequested(pending.scenario.id));
    }
    super.dispose();
  }

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

  void _stageDelete(SavedScenario scenario) {
    // Tek bir görünür undo yüzeyi tutuyoruz. Kullanıcı art arda ikinci kartı
    // silerse önceki işlem kesinleşir ve yeni kart kendi 5 saniyesini alır.
    final previous = _undoableDeletion;
    if (previous != null) {
      unawaited(_commitDeletion(previous));
    }

    final pending = _PendingScenarioDeletion(scenario);
    _undoableDeletion = pending;
    setState(() => _pendingDeleteIds.add(scenario.id));
    pending.timer = Timer(
      _scenarioUndoWindow,
      () => unawaited(_commitDeletion(pending)),
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _scenarioUndoWindow,
          behavior: SnackBarBehavior.floating,
          content: _ScenarioDeleteUndoContent(
            onUndo: () => _undoDeletion(pending),
          ),
        ),
      );
  }

  void _undoDeletion(_PendingScenarioDeletion pending) {
    if (pending.committed || !identical(_undoableDeletion, pending)) return;
    pending.timer?.cancel();
    _undoableDeletion = null;
    setState(() => _pendingDeleteIds.remove(pending.scenario.id));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  Future<void> _commitDeletion(_PendingScenarioDeletion pending) async {
    if (pending.committed) return;
    pending.committed = true;
    pending.timer?.cancel();
    if (identical(_undoableDeletion, pending)) {
      _undoableDeletion = null;
    }

    final completion = Completer<bool>();
    _scenariosBloc.add(
      ScenarioDeleteRequested(pending.scenario.id, completion: completion),
    );
    await completion.future;
    if (mounted) {
      setState(() => _pendingDeleteIds.remove(pending.scenario.id));
    }
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

          final visibleScenarios = state.scenarios
              .where((scenario) => !_pendingDeleteIds.contains(scenario.id))
              .toList(growable: false);

          if (visibleScenarios.isEmpty) {
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
              itemCount: visibleScenarios.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final scenario = visibleScenarios[i];
                return _SwipeToDeleteCard(
                  key: ValueKey(scenario.id),
                  scenario: scenario,
                  onDelete: () => _stageDelete(scenario),
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
