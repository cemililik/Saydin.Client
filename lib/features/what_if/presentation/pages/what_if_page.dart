import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/widgets/settings_icon_button.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_event.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_state.dart';
import 'package:saydin/features/what_if/presentation/widgets/amount_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/asset_selector.dart';
import 'package:saydin/features/what_if/presentation/widgets/date_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/result_card.dart';
import 'package:saydin/features/what_if/presentation/widgets/reverse_result_card.dart';
import 'package:saydin/features/what_if/presentation/widgets/reverse_share_card_widget.dart';
import 'package:saydin/core/widgets/inflation_toggle.dart';
import 'package:saydin/core/widgets/skeleton_card.dart';
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
  num? _lastSyncedAmount;

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

    final bloc = context.read<WhatIfBloc>();
    if (formInput.calculationMode == CalculationMode.reverse) {
      bloc.add(
        WhatIfReverseCalculateRequested(
          assetSymbol: symbol,
          buyDate: buyDate,
          sellDate: formInput.sellDate,
          targetAmount: amount,
          targetAmountType: formInput.amountType,
          includeInflation: formInput.includeInflation,
        ),
      );
    } else {
      bloc.add(
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
      appBar: AppBar(
        title: const _BrandedTitle(),
        centerTitle: true,
        actions: const [SettingsIconButton()],
      ),
      body: BlocConsumer<WhatIfBloc, WhatIfState>(
        listenWhen: (prev, curr) =>
            curr is WhatIfSuccess ||
            curr is WhatIfFailure ||
            prev.formInput.amount != curr.formInput.amount ||
            (!prev.formInput.dateAdjusted && curr.formInput.dateAdjusted),
        listener: (context, state) {
          if (state is WhatIfSuccess) {
            HapticFeedback.mediumImpact();
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
          // Tutar alanını yalnızca BLoC'tan gelen amount değiştiğinde güncelle
          // (replay gibi). Hesaplama sonucu geldiğinde kullanıcının yazdığını ezme.
          final amount = state.formInput.amount;
          final prevAmount = _lastSyncedAmount;
          if (amount != null && amount != prevAmount) {
            _lastSyncedAmount = amount;
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
          final reverseResult = state is WhatIfSuccess
              ? state.reverseResult
              : null;
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
          final hasResult = successResult != null || reverseResult != null;
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
            calculationMode: formInput.calculationMode,
            result: successResult,
            reverseResult: reverseResult,
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
            onModeChanged: (mode) =>
                context.read<WhatIfBloc>().add(WhatIfModeChanged(mode)),
            onCalculate: _onCalculate,
            onShare: hasResult
                ? () {
                    final fmt = NumberFormat.currency(
                      locale: 'tr_TR',
                      symbol: '₺',
                      decimalDigits: 0,
                    );
                    if (reverseResult != null) {
                      final r = reverseResult;
                      final pct = r.profitLossPercent;
                      final sign = pct >= 0 ? '+' : '';
                      final text = context.l10n.shareTextReverse(
                        r.assetDisplayName,
                        fmt.format(r.targetValueTry),
                        fmt.format(r.requiredInvestmentTry),
                        '$sign${pct.toStringAsFixed(2).replaceAll('.', ',')}%',
                      );
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ShareCardPreviewSheet(
                          cardWidgetOverride: ReverseShareCardWidget(result: r),
                          shareText: text,
                        ),
                      );
                    } else if (successResult != null) {
                      final r = successResult;
                      final pct = r.profitLossPercent;
                      final sign = pct >= 0 ? '+' : '';
                      final text = context.l10n.shareTextWhatIf(
                        r.assetDisplayName,
                        fmt.format(r.initialValueTry),
                        fmt.format(r.finalValueTry),
                        '$sign${pct.toStringAsFixed(2).replaceAll('.', ',')}%',
                      );
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ShareCardPreviewSheet(
                          result: successResult,
                          shareText: text,
                        ),
                      );
                    }
                  }
                : null,
            onSave: hasResult
                ? () {
                    final assetSymbol =
                        reverseResult?.assetSymbol ??
                        successResult!.assetSymbol;
                    final assetDisplayName =
                        reverseResult?.assetDisplayName ??
                        successResult!.assetDisplayName;
                    final buyDate =
                        reverseResult?.buyDate ?? successResult!.buyDate;
                    final sellDate =
                        reverseResult?.sellDate ?? successResult!.sellDate;
                    context.read<ScenariosBloc>().add(
                      ScenarioSaveRequested(
                        assetSymbol: assetSymbol,
                        assetDisplayName: assetDisplayName,
                        buyDate: buyDate,
                        sellDate: sellDate,
                        amount: _amountController.text.isEmpty
                            ? 0
                            : num.tryParse(
                                    _amountController.text.replaceAll(',', '.'),
                                  ) ??
                                  0,
                        amountType: formInput.amountType,
                        extraData: {
                          'includeInflation': formInput.includeInflation,
                          if (formInput.calculationMode ==
                              CalculationMode.reverse)
                            'mode': 'reverse',
                        },
                      ),
                    );
                  }
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
    required this.calculationMode,
    required this.result,
    required this.onAssetChanged,
    required this.onBuyDateChanged,
    required this.onSellDateChanged,
    required this.onAmountTypeChanged,
    required this.onModeChanged,
    required this.onCalculate,
    required this.includeInflation,
    required this.inflationEnabled,
    required this.onInflationToggled,
    this.reverseResult,
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
  final CalculationMode calculationMode;
  final WhatIfResult? result;
  final ReverseWhatIfResult? reverseResult;
  final ValueChanged<String?> onAssetChanged;
  final ValueChanged<DateTime?> onBuyDateChanged;
  final ValueChanged<DateTime?> onSellDateChanged;
  final ValueChanged<String> onAmountTypeChanged;
  final ValueChanged<CalculationMode> onModeChanged;
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
    final isReverse = calculationMode == CalculationMode.reverse;

    final buttonLabel = isReverse
        ? (isCalculating ? l10n.reverseCalculating : l10n.reverseCalculate)
        : (isCalculating ? l10n.calculating : l10n.calculate);

    final amountLabel = isReverse ? l10n.targetAmount : null;
    final amountValidator = isReverse ? l10n.enterTargetAmount : null;

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
              // ── Mod seçici ──────────────────────────────────────────────
              SegmentedButton<CalculationMode>(
                segments: [
                  ButtonSegment(
                    value: CalculationMode.normal,
                    label: Text(l10n.modeNormal),
                    icon: const Icon(Icons.calculate_outlined),
                  ),
                  ButtonSegment(
                    value: CalculationMode.reverse,
                    label: Text(l10n.modeReverse),
                    icon: const Icon(Icons.swap_vert),
                  ),
                ],
                selected: {calculationMode},
                onSelectionChanged: (s) => onModeChanged(s.first),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 13,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isReverse ? l10n.modeReverseHint : l10n.modeNormalHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                amountType: isReverse ? 'try' : amountType,
                allowedTypes: isReverse
                    ? const ['try']
                    : assets
                              .where((a) => a.symbol == selectedSymbol)
                              .map((a) => a.allowedAmountTypes)
                              .firstOrNull ??
                          const ['try'],
                onAmountTypeChanged: onAmountTypeChanged,
                labelOverride: amountLabel,
                validatorOverride: amountValidator,
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
                    : Icon(isReverse ? Icons.swap_vert : Icons.calculate),
                label: Text(buttonLabel),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (isCalculating) ...[
                const SizedBox(height: 24),
                const SkeletonCard(),
              ],
              // ── Normal sonuç ────────────────────────────────────────────
              if (result case final result?) ...[
                const SizedBox(height: 24),
                ResultCard(result: result),
                const SizedBox(height: 12),
                _ActionButtons(onSave: onSave, onShare: onShare),
              ],
              // ── Ters hesaplama sonucu ───────────────────────────────────
              if (reverseResult case final rr?) ...[
                const SizedBox(height: 24),
                ReverseResultCard(result: rr),
                const SizedBox(height: 12),
                _ActionButtons(onSave: onSave, onShare: onShare),
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

class _ActionButtons extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const _ActionButtons({this.onSave, this.onShare});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
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
