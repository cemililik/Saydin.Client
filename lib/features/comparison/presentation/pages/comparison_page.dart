import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
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

  @override
  void initState() {
    super.initState();
    context.read<ComparisonBloc>().add(const ComparisonAssetsRequested());
  }

  @override
  void dispose() {
    _amountController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.compareTitle), centerTitle: false),
        body: BlocBuilder<ComparisonBloc, ComparisonState>(
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
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Asset chips ──────────────────────────────────
                  Text(
                    l10n.compareSelectAssets,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _AssetChips(
                    assets: state.assets,
                    selected: state.selectedSymbols,
                    enabled: !isCalculating,
                  ),
                  const SizedBox(height: 16),

                  // ── Dates ────────────────────────────────────────
                  DateInput(
                    label: l10n.buyDate,
                    value: state.buyDate,
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
                    required: false,
                    onChanged: (d) => context.read<ComparisonBloc>().add(
                      ComparisonSellDateChanged(d),
                    ),
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
                  const SizedBox(height: 20),

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

class _AssetChips extends StatelessWidget {
  final List<Asset> assets;
  final List<String> selected;
  final bool enabled;

  const _AssetChips({
    required this.assets,
    required this.selected,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: assets.map((asset) {
        final isSelected = selected.contains(asset.symbol);
        final canSelect = isSelected || selected.length < 5;
        return FilterChip(
          label: Text(asset.displayName),
          selected: isSelected,
          onSelected: enabled && canSelect
              ? (_) => context.read<ComparisonBloc>().add(
                  ComparisonSymbolToggled(asset.symbol),
                )
              : null,
        );
      }).toList(),
    );
  }
}
