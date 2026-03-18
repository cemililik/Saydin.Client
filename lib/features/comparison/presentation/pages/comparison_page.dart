import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/widgets/settings_icon_button.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/core/widgets/inflation_toggle.dart';
import 'package:saydin/core/widgets/share_preview_sheet.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_event.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_state.dart';
import 'package:saydin/features/comparison/presentation/widgets/comparison_result_card.dart';
import 'package:saydin/features/comparison/presentation/widgets/comparison_share_card_widget.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart';
import 'package:saydin/core/widgets/skeleton_card.dart';
import 'package:saydin/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/presentation/widgets/amount_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/date_input.dart';

class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ComparisonBloc>().add(const ComparisonAssetsRequested());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCompare(ComparisonState state) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (state.selectedSymbols.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.compareMinAssets)));
      return;
    }
    final raw = _amountController.text.replaceAll(',', '.');
    final amount = num.tryParse(raw);
    if (amount == null || amount <= 0) return;
    context.read<ComparisonBloc>()
      ..add(ComparisonAmountChanged(amount))
      ..add(const ComparisonCalculateRequested());
  }

  void _saveComparisonScenario(BuildContext ctx, ComparisonSuccess state) {
    if (state.buyDate == null) return;
    final winner = state.result.results.firstOrNull;
    final symbols = state.selectedSymbols.join(',');
    ctx.read<ScenariosBloc>().add(
      ScenarioSaveRequested(
        assetSymbol: symbols,
        assetDisplayName: ctx.l10n.scenarioNameComparison(
          state.result.results.length,
        ),
        buyDate: state.buyDate!,
        sellDate: state.sellDate,
        amount: state.amount ?? 0,
        amountType: 'try',
        type: ScenarioType.comparison,
        extraData: {
          'winnerSymbol': winner?.calculation.assetSymbol ?? '',
          'winnerName': winner?.calculation.assetDisplayName ?? '',
          'winnerReturn': winner?.calculation.profitLossPercent ?? 0.0,
          'includeInflation': state.includeInflation,
        },
      ),
    );
  }

  void _showComparisonShare(
    BuildContext ctx,
    CompareResult result,
    DateTime? buyDate,
    DateTime? sellDate,
  ) {
    if (buyDate == null) return;
    final winner = result.results.firstOrNull;
    final winnerName = winner?.calculation.assetDisplayName ?? '';
    final winnerPct = winner?.calculation.profitLossPercent ?? 0;
    final sign = winnerPct >= 0 ? '+' : '';
    final shareText = ctx.l10n.shareTextComparison(
      winnerName,
      '$sign${winnerPct.toStringAsFixed(2).replaceAll('.', ',')}%',
    );
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => SharePreviewSheet(
        shareText: shareText,
        cardWidget: ComparisonShareCardWidget(
          result: result,
          buyDate: buyDate,
          sellDate: sellDate,
        ),
      ),
    );
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

  void _showAssetPicker(BuildContext pageContext) {
    final bloc = pageContext.read<ComparisonBloc>();
    final favoritesCubit = pageContext.read<FavoritesCubit>();
    showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider.value(value: favoritesCubit),
        ],
        child: const _AssetPickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.compareTitle),
          centerTitle: true,
          actions: const [SettingsIconButton()],
        ),
        body: BlocConsumer<ComparisonBloc, ComparisonState>(
          listenWhen: (_, curr) => curr is ComparisonSuccess,
          listener: (context, state) {
            if (state is ComparisonSuccess) {
              HapticFeedback.mediumImpact();
            }
            if (state is ComparisonSuccess && state.amount != null) {
              final controllerAmount = num.tryParse(
                _amountController.text.replaceAll(',', '.'),
              );
              if (controllerAmount != state.amount) {
                _amountController.text = state.amount.toString().replaceAll(
                  '.',
                  ',',
                );
              }
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                );
              }
            });
          },
          builder: (context, state) {
            if (state is ComparisonInitial ||
                state is ComparisonAssetsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ComparisonFailure && state.assets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage(state.error, l10n)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<ComparisonBloc>().add(
                        const ComparisonAssetsRequested(),
                      ),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }

            final isCalculating = state is ComparisonCalculating;

            return Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Selected assets ──────────────────────────────
                  Text(
                    l10n.compareSelectAssets,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _SelectedAssetChips(
                    assets: state.assets,
                    selectedSymbols: state.selectedSymbols,
                    isCalculating: isCalculating,
                    onRemove: (symbol) => context.read<ComparisonBloc>().add(
                      ComparisonSymbolToggled(symbol),
                    ),
                    onAdd: () => _showAssetPicker(context),
                  ),
                  const SizedBox(height: 16),

                  // ── Dates ────────────────────────────────────────
                  Builder(
                    builder: (context) {
                      final priceHistoryMonths = context
                          .read<AppConfigCubit>()
                          .state
                          .features
                          .priceHistoryMonths;
                      final range = comparisonDateRange(
                        assets: state.assets,
                        selectedSymbols: state.selectedSymbols,
                        priceHistoryMonths: priceHistoryMonths,
                      );
                      return Column(
                        children: [
                          DateInput(
                            label: l10n.buyDate,
                            value: state.buyDate,
                            firstDate: range.firstDate,
                            lastDate: range.lastDate,
                            onChanged: (d) {
                              if (d != null) {
                                context.read<ComparisonBloc>().add(
                                  ComparisonBuyDateChanged(d),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DateInput(
                            label: l10n.sellDate,
                            value: state.sellDate,
                            firstDate: state.buyDate ?? range.firstDate,
                            lastDate: range.lastDate,
                            required: false,
                            onChanged: (d) => context
                                .read<ComparisonBloc>()
                                .add(ComparisonSellDateChanged(d)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Amount ───────────────────────────────────────
                  AmountInput(
                    controller: _amountController,
                    amountType: state.amountType,
                    allowedTypes: const ['try'],
                    onAmountTypeChanged: (t) => context
                        .read<ComparisonBloc>()
                        .add(ComparisonAmountTypeChanged(t)),
                  ),
                  const SizedBox(height: 8),

                  // ── Inflation toggle ─────────────────────────────
                  Builder(
                    builder: (context) {
                      final inflationEnabled = context
                          .read<AppConfigCubit>()
                          .state
                          .features
                          .inflationAdjustment;
                      return InflationToggle(
                        value: state.includeInflation,
                        enabled: inflationEnabled,
                        onToggle: () => context.read<ComparisonBloc>().add(
                          const ComparisonInflationToggled(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Compare button ───────────────────────────────
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isCalculating ? null : () => _onCompare(state),
                      icon: isCalculating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.compare_arrows),
                      label: Text(
                        isCalculating ? l10n.comparing : l10n.compareButton,
                      ),
                    ),
                  ),

                  // ── Error ────────────────────────────────────────
                  if (state is ComparisonFailure) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage(state.error, l10n),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // ── Skeleton loading ─────────────────────────────
                  if (isCalculating) ...[
                    const SizedBox(height: 24),
                    const SkeletonCard(),
                  ],

                  // ── Results ──────────────────────────────────────
                  if (state is ComparisonSuccess) ...[
                    const SizedBox(height: 24),
                    Text(
                      l10n.compareResultTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...state.result.results.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ComparisonResultCard(item: item),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _saveComparisonScenario(context, state),
                            icon: const Icon(Icons.bookmark_outline),
                            label: Text(l10n.saveScenario),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showComparisonShare(
                              context,
                              state.result,
                              state.buyDate,
                              state.sellDate,
                            ),
                            icon: const Icon(Icons.share_outlined),
                            label: Text(l10n.shareResult),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Selected assets row ──────────────────────────────────────────────────────

class _SelectedAssetChips extends StatelessWidget {
  final List<Asset> assets;
  final List<String> selectedSymbols;
  final bool isCalculating;
  final void Function(String symbol) onRemove;
  final VoidCallback onAdd;

  const _SelectedAssetChips({
    required this.assets,
    required this.selectedSymbols,
    required this.isCalculating,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final symbol in selectedSymbols)
          Chip(
            label: Text(
              assets.firstWhere((a) => a.symbol == symbol).displayName,
            ),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: isCalculating ? null : () => onRemove(symbol),
          ),
        if (!isCalculating && selectedSymbols.length < 5)
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: Text(l10n.compareAddAsset),
            onPressed: onAdd,
          ),
      ],
    );
  }
}

// ── Asset picker bottom sheet ────────────────────────────────────────────────

class _AssetPickerSheet extends StatefulWidget {
  const _AssetPickerSheet();

  @override
  State<_AssetPickerSheet> createState() => _AssetPickerSheetState();
}

class _AssetPickerSheetState extends State<_AssetPickerSheet> {
  static const _categoryOrder = [
    'currency',
    'precious_metal',
    'crypto',
    'stock',
  ];

  final _searchController = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Asset> _filtered(List<Asset> assets) {
    final q = _query.toLowerCase();
    return assets.where((a) {
      final matchesCat = _category == null || a.category == _category;
      final matchesSearch =
          q.isEmpty ||
          a.displayName.toLowerCase().contains(q) ||
          a.symbol.toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();
  }

  String _categoryLabel(String category, AppLocalizations l10n) =>
      switch (category) {
        'favorites' => l10n.categoryFavorites,
        'currency' => l10n.categoryCurrency,
        'precious_metal' => l10n.categoryPreciousMetal,
        'crypto' => l10n.categoryCrypto,
        'stock' => l10n.categoryStock,
        _ => category,
      };

  /// Groups filtered assets by category, with favorites section at top.
  List<Object> _groupedItems(List<Asset> filtered, Set<String> favorites) {
    if (_category != null) return filtered;

    final grouped = <String, List<Asset>>{};
    for (final a in filtered) {
      grouped.putIfAbsent(a.category, () => []).add(a);
    }

    final items = <Object>[];

    // Favoriler bölümü (en üstte)
    if (favorites.isNotEmpty) {
      final favoriteAssets = filtered
          .where((a) => favorites.contains(a.symbol))
          .toList();
      if (favoriteAssets.isNotEmpty) {
        items.add('favorites');
        items.addAll(favoriteAssets);
      }
    }

    // Kategoriler
    for (final cat in _categoryOrder) {
      final list = grouped[cat];
      if (list == null || list.isEmpty) continue;
      items.add(cat);
      items.addAll(list);
    }
    // Sıralamada olmayan kategoriler
    for (final cat in grouped.keys) {
      if (_categoryOrder.contains(cat)) continue;
      items.add(cat);
      items.addAll(grouped[cat]!);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final categories = <String?, String>{
      null: l10n.compareAllCategories,
      'currency': l10n.categoryCurrency,
      'precious_metal': l10n.categoryPreciousMetal,
      'crypto': l10n.categoryCrypto,
      'stock': l10n.categoryStock,
    };

    return BlocBuilder<ComparisonBloc, ComparisonState>(
      builder: (context, state) {
        final filtered = _filtered(state.assets);
        final selected = state.selectedSymbols;

        return BlocBuilder<FavoritesCubit, Set<String>>(
          builder: (context, favorites) {
            final useGrouped = _query.isEmpty && _category == null;
            final items = useGrouped
                ? _groupedItems(filtered, favorites)
                : filtered;

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: l10n.searchAsset,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: categories.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: _category == entry.key,
                            onSelected: (_) =>
                                setState(() => _category = entry.key),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),

                  const Divider(height: 1),

                  // Asset list
                  Expanded(
                    child: items.isEmpty
                        ? Center(child: Text(l10n.compareNoAssetsFound))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final item = items[i];

                              // Kategori başlığı
                              if (item is String) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    4,
                                  ),
                                  child: Text(
                                    _categoryLabel(item, l10n).toUpperCase(),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                );
                              }

                              final asset = item as Asset;
                              final isSelected = selected.contains(
                                asset.symbol,
                              );
                              final canSelect =
                                  isSelected || selected.length < 5;
                              final isFav = favorites.contains(asset.symbol);
                              final cubit = context.read<FavoritesCubit>();

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: canSelect
                                    ? (_) => context.read<ComparisonBloc>().add(
                                        ComparisonSymbolToggled(asset.symbol),
                                      )
                                    : null,
                                title: Text(asset.displayName),
                                subtitle: Text(
                                  asset.symbol,
                                  style: theme.textTheme.bodySmall,
                                ),
                                secondary: IconButton(
                                  icon: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    color: isFav
                                        ? Colors.amber
                                        : theme.colorScheme.outlineVariant,
                                  ),
                                  onPressed: () {
                                    if (!isFav && cubit.isFull) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            l10n.favoritesMaxReached(
                                              FavoritesCubit.maxFavorites,
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    cubit.toggle(asset.symbol);
                                  },
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
