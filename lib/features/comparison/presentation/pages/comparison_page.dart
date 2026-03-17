import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_event.dart';
import 'package:saydin/features/comparison/presentation/bloc/comparison_state.dart';
import 'package:saydin/features/comparison/presentation/widgets/comparison_result_card.dart';
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

  void _showAssetPicker(BuildContext pageContext) {
    final bloc = pageContext.read<ComparisonBloc>();
    showModalBottomSheet<void>(
      context: pageContext,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _AssetPickerSheet()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.compareTitle), centerTitle: false),
        body: BlocConsumer<ComparisonBloc, ComparisonState>(
          listenWhen: (_, curr) => curr is ComparisonSuccess,
          listener: (context, state) {
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
                    Text(state.message),
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
                      return _InflationToggle(
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
                      state.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

// ── Inflation toggle ──────────────────────────────────────────────────────────

class _InflationToggle extends StatelessWidget {
  final bool value;
  final bool enabled;
  final VoidCallback onToggle;

  const _InflationToggle({
    required this.value,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: enabled ? onToggle : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Switch(
              value: enabled ? value : false,
              onChanged: enabled ? (_) => onToggle() : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.inflationAdjust,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (!enabled) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.premiumFeature,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    l10n.inflationAdjustSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                  color: Theme.of(context).colorScheme.outlineVariant,
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
                child: filtered.isEmpty
                    ? Center(child: Text(l10n.compareNoAssetsFound))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final asset = filtered[i];
                          final isSelected = selected.contains(asset.symbol);
                          final canSelect = isSelected || selected.length < 5;
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
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
