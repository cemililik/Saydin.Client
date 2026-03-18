import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_event.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_state.dart';
import 'package:saydin/features/what_if/presentation/widgets/amount_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/asset_selector.dart';
import 'package:saydin/features/what_if/presentation/widgets/date_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/result_card.dart';
import 'package:saydin/core/widgets/inflation_toggle.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_preview_sheet.dart';

class WhatIfPage extends StatefulWidget {
  const WhatIfPage({super.key});

  @override
  State<WhatIfPage> createState() => _WhatIfPageState();
}

class _WhatIfPageState extends State<WhatIfPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<WhatIfBloc>().add(const WhatIfAssetsRequested());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    if (_formKey.currentState?.validate() != true) return;

    final formInput = context.read<WhatIfBloc>().state.formInput;

    final symbol = formInput.selectedSymbol;
    if (symbol == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.assetRequired)));
      return;
    }
    final buyDate = formInput.buyDate;
    if (buyDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.buyDateRequired)));
      return;
    }

    final amount = num.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validAmountRequired)));
      return;
    }

    context.read<WhatIfBloc>().add(
      WhatIfCalculateRequested(
        assetSymbol: symbol,
        buyDate: buyDate,
        sellDate: formInput.sellDate,
        amount: amount,
        amountType: formInput.amountType,
        includeInflation: formInput.includeInflation,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const _BrandedTitle(), centerTitle: true),
      body: BlocConsumer<WhatIfBloc, WhatIfState>(
        listenWhen: (prev, curr) =>
            curr is WhatIfSuccess ||
            curr is WhatIfFailure ||
            prev.formInput.amount != curr.formInput.amount ||
            (!prev.formInput.dateAdjusted && curr.formInput.dateAdjusted),
        listener: (context, state) {
          if (state is WhatIfSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                );
              }
            });
          }
          if (state is WhatIfFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_errorMessage(state.error, context.l10n)),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
          if (state.formInput.dateAdjusted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.dateAdjustedWarning)),
            );
          }
          final amount = state.formInput.amount;
          if (amount != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _amountController.text = amount.toString().replaceAll('.', ',');
              }
            });
          }
        },
        builder: (context, state) {
          if (state is WhatIfAssetsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final assets = switch (state) {
            WhatIfAssetsLoaded(:final assets) => assets,
            WhatIfCalculating(:final assets) => assets,
            WhatIfSuccess(:final assets) => assets,
            WhatIfFailure(:final assets) => assets,
            _ => <Asset>[],
          };

          final formInput = state.formInput;
          final successResult = state is WhatIfSuccess ? state.result : null;
          final selectedAsset = assets
              .where((a) => a.symbol == formInput.selectedSymbol)
              .firstOrNull;
          final priceHistoryMonths = context
              .read<AppConfigCubit>()
              .state
              .features
              .priceHistoryMonths;
          final dateRange = assetDateRange(
            assetFirstDate: selectedAsset?.firstDate,
            assetLastDate: selectedAsset?.lastDate,
            priceHistoryMonths: priceHistoryMonths,
          );

          final config = context.read<AppConfigCubit>().state;
          return _WhatIfForm(
            formKey: _formKey,
            scrollController: _scrollController,
            assets: assets,
            selectedSymbol: formInput.selectedSymbol,
            buyDate: formInput.buyDate,
            sellDate: formInput.sellDate,
            amountType: formInput.amountType,
            amountController: _amountController,
            isCalculating: state is WhatIfCalculating,
            result: successResult,
            assetFirstDate: dateRange.firstDate,
            assetLastDate: dateRange.lastDate,
            includeInflation: formInput.includeInflation,
            inflationEnabled: config.features.inflationAdjustment,
            onAssetChanged: (v) =>
                context.read<WhatIfBloc>().add(WhatIfSymbolChanged(v)),
            onBuyDateChanged: (v) =>
                context.read<WhatIfBloc>().add(WhatIfBuyDateChanged(v)),
            onSellDateChanged: (v) =>
                context.read<WhatIfBloc>().add(WhatIfSellDateChanged(v)),
            onAmountTypeChanged: (v) =>
                context.read<WhatIfBloc>().add(WhatIfAmountTypeChanged(v)),
            onInflationToggled: () =>
                context.read<WhatIfBloc>().add(const WhatIfInflationToggled()),
            onCalculate: _onCalculate,
            onShare: successResult != null
                ? () {
                    final r = successResult;
                    final fmt = NumberFormat.currency(
                      locale: 'tr_TR',
                      symbol: '₺',
                      decimalDigits: 0,
                    );
                    final pct = r.profitLossPercent;
                    final sign = pct >= 0 ? '+' : '';
                    final text =
                        '${r.assetDisplayName}\'e ${fmt.format(r.initialValueTry)} '
                        'yatırsaydım ${fmt.format(r.finalValueTry)} ederdi '
                        '($sign${pct.toStringAsFixed(2).replaceAll('.', ',')}%)! 📊 #saydın';
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ShareCardPreviewSheet(
                        result: successResult,
                        shareText: text,
                      ),
                    );
                  }
                : null,
            onSave: successResult != null
                ? () => context.read<ScenariosBloc>().add(
                    ScenarioSaveRequested(
                      assetSymbol: successResult.assetSymbol,
                      assetDisplayName: successResult.assetDisplayName,
                      buyDate: successResult.buyDate,
                      sellDate: successResult.sellDate,
                      amount: _amountController.text.isEmpty
                          ? 0
                          : num.tryParse(
                                  _amountController.text.replaceAll(',', '.'),
                                ) ??
                                0,
                      amountType: formInput.amountType,
                      extraData: {
                        'includeInflation': formInput.includeInflation,
                      },
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _WhatIfForm extends StatelessWidget {
  const _WhatIfForm({
    required this.formKey,
    required this.scrollController,
    required this.assets,
    required this.selectedSymbol,
    required this.buyDate,
    required this.sellDate,
    required this.amountType,
    required this.amountController,
    required this.isCalculating,
    required this.result,
    required this.onAssetChanged,
    required this.onBuyDateChanged,
    required this.onSellDateChanged,
    required this.onAmountTypeChanged,
    required this.onCalculate,
    required this.includeInflation,
    required this.inflationEnabled,
    required this.onInflationToggled,
    this.assetFirstDate,
    this.assetLastDate,
    this.onSave,
    this.onShare,
  });

  final GlobalKey<FormState> formKey;
  final ScrollController scrollController;
  final List<Asset> assets;
  final String? selectedSymbol;
  final DateTime? buyDate;
  final DateTime? sellDate;
  final String amountType;
  final TextEditingController amountController;
  final bool isCalculating;
  final WhatIfResult? result;
  final ValueChanged<String?> onAssetChanged;
  final ValueChanged<DateTime?> onBuyDateChanged;
  final ValueChanged<DateTime?> onSellDateChanged;
  final ValueChanged<String> onAmountTypeChanged;
  final VoidCallback onCalculate;
  final bool includeInflation;
  final bool inflationEnabled;
  final VoidCallback onInflationToggled;
  final DateTime? assetFirstDate;
  final DateTime? assetLastDate;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AssetSelector(
                assets: assets,
                selectedSymbol: selectedSymbol,
                onChanged: onAssetChanged,
              ),
              const SizedBox(height: 16),
              DateInput(
                label: l10n.buyDate,
                value: buyDate,
                firstDate: assetFirstDate,
                lastDate: assetLastDate ?? DateTime.now(),
                onChanged: onBuyDateChanged,
              ),
              const SizedBox(height: 16),
              DateInput(
                label: l10n.sellDate,
                value: sellDate,
                firstDate: buyDate ?? assetFirstDate,
                lastDate: assetLastDate ?? DateTime.now(),
                required: false,
                onChanged: onSellDateChanged,
              ),
              const SizedBox(height: 16),
              AmountInput(
                controller: amountController,
                amountType: amountType,
                allowedTypes:
                    assets
                        .where((a) => a.symbol == selectedSymbol)
                        .map((a) => a.allowedAmountTypes)
                        .firstOrNull ??
                    const ['try'],
                onAmountTypeChanged: onAmountTypeChanged,
              ),
              const SizedBox(height: 8),
              InflationToggle(
                value: includeInflation,
                enabled: inflationEnabled,
                onToggle: onInflationToggled,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: isCalculating ? null : onCalculate,
                icon: isCalculating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calculate),
                label: Text(isCalculating ? l10n.calculating : l10n.calculate),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (result case final result?) ...[
                const SizedBox(height: 24),
                ResultCard(result: result),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSave,
                        icon: const Icon(Icons.bookmark_border),
                        label: Text(l10n.saveScenario),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
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
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.priceDisclaimer,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Branded AppBar title ──────────────────────────────────────────────────────

class _BrandedTitle extends StatelessWidget {
  const _BrandedTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primary = Theme.of(context).colorScheme.primary;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: l10n.brandedTitlePrefix,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextSpan(
            text: l10n.brandedTitleSuffix,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
