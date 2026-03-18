import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/date_range_utils.dart';
import 'package:saydin/core/widgets/inflation_toggle.dart';
import 'package:saydin/core/widgets/settings_icon_button.dart';
import 'package:saydin/core/widgets/skeleton_card.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_bloc.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_event.dart';
import 'package:saydin/features/dca/presentation/bloc/dca_state.dart';
import 'package:saydin/features/dca/presentation/widgets/dca_result_card.dart';
import 'package:saydin/features/dca/presentation/widgets/period_selector.dart';
import 'package:saydin/features/dca/presentation/widgets/dca_share_card_preview_sheet.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/presentation/widgets/asset_selector.dart';
import 'package:saydin/features/what_if/presentation/widgets/date_input.dart';
import 'package:saydin/l10n/app_localizations.dart';

class DcaPage extends StatefulWidget {
  const DcaPage({super.key});

  @override
  State<DcaPage> createState() => _DcaPageState();
}

class _DcaPageState extends State<DcaPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<DcaBloc>().add(const DcaAssetsRequested());
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

    final formInput = context.read<DcaBloc>().state.formInput;

    final symbol = formInput.selectedSymbol;
    if (symbol == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.assetRequired)));
      return;
    }
    final startDate = formInput.startDate;
    if (startDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.dcaStartDateRequired)));
      return;
    }

    final amount = num.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validAmountRequired)));
      return;
    }

    context.read<DcaBloc>().add(
      DcaCalculateRequested(
        assetSymbol: symbol,
        startDate: startDate,
        endDate: formInput.endDate,
        periodicAmount: amount,
        period: formInput.period,
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
      appBar: AppBar(
        title: Text(context.l10n.dcaTitle),
        centerTitle: true,
        actions: const [SettingsIconButton()],
      ),
      body: BlocConsumer<DcaBloc, DcaState>(
        listenWhen: (prev, curr) =>
            curr is DcaSuccess ||
            curr is DcaFailure ||
            prev.formInput.periodicAmount != curr.formInput.periodicAmount,
        listener: (context, state) {
          if (state is DcaSuccess) {
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
          if (state is DcaFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_errorMessage(state.error, context.l10n)),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
          final amount = state.formInput.periodicAmount;
          if (amount != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _amountController.text = amount.toString().replaceAll('.', ',');
              }
            });
          }
        },
        builder: (context, state) {
          if (state is DcaAssetsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final assets = switch (state) {
            DcaAssetsLoaded(:final assets) => assets,
            DcaCalculating(:final assets) => assets,
            DcaSuccess(:final assets) => assets,
            DcaFailure(:final assets) => assets,
            _ => <Asset>[],
          };

          final formInput = state.formInput;
          final successResult = state is DcaSuccess ? state.result : null;
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
          final l10n = context.l10n;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AssetSelector(
                      assets: assets,
                      selectedSymbol: formInput.selectedSymbol,
                      onChanged: (v) =>
                          context.read<DcaBloc>().add(DcaSymbolChanged(v)),
                    ),
                    const SizedBox(height: 16),
                    DateInput(
                      label: l10n.dcaStartDate,
                      value: formInput.startDate,
                      firstDate: dateRange.firstDate,
                      lastDate: dateRange.lastDate ?? DateTime.now(),
                      onChanged: (v) =>
                          context.read<DcaBloc>().add(DcaStartDateChanged(v!)),
                    ),
                    const SizedBox(height: 16),
                    DateInput(
                      label: l10n.dcaEndDate,
                      value: formInput.endDate,
                      firstDate: formInput.startDate ?? dateRange.firstDate,
                      lastDate: dateRange.lastDate ?? DateTime.now(),
                      required: false,
                      onChanged: (v) =>
                          context.read<DcaBloc>().add(DcaEndDateChanged(v)),
                    ),
                    const SizedBox(height: 16),
                    PeriodSelector(
                      value: formInput.period,
                      onChanged: (v) =>
                          context.read<DcaBloc>().add(DcaPeriodChanged(v)),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.dcaPeriodicAmountLabel,
                        hintText: l10n.amountHint,
                        prefixText: '₺ ',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.enterAmount;
                        }
                        final parsed = num.tryParse(v.replaceAll(',', '.'));
                        if (parsed == null || parsed <= 0) {
                          return l10n.validAmountRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    InflationToggle(
                      value: formInput.includeInflation,
                      enabled: config.features.inflationAdjustment,
                      onToggle: () => context.read<DcaBloc>().add(
                        const DcaInflationToggled(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: state is DcaCalculating ? null : _onCalculate,
                      icon: state is DcaCalculating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.calculate),
                      label: Text(
                        state is DcaCalculating
                            ? l10n.calculating
                            : l10n.dcaCalculate,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    if (state is DcaCalculating) ...[
                      const SizedBox(height: 24),
                      const SkeletonCard(),
                    ],
                    if (successResult case final result?) ...[
                      const SizedBox(height: 24),
                      DcaResultCard(result: result),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<ScenariosBloc>().add(
                                  ScenarioSaveRequested(
                                    assetSymbol: result.assetSymbol,
                                    assetDisplayName: result.assetDisplayName,
                                    buyDate: result.startDate,
                                    sellDate: result.endDate,
                                    amount: result.periodicAmount,
                                    amountType: 'try',
                                    type: ScenarioType.dca,
                                    extraData: {
                                      'includeInflation':
                                          formInput.includeInflation,
                                      'period': result.period,
                                      'periodicAmount': result.periodicAmount,
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.bookmark_border),
                              label: Text(l10n.saveScenario),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          if (config.features.share) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final sign = result.profitLossPercent >= 0
                                      ? '+'
                                      : '';
                                  final pct = result.profitLossPercent;
                                  final text = l10n.shareTextDca(
                                    result.assetDisplayName,
                                    result.totalPurchases,
                                    '$sign${pct.toStringAsFixed(2).replaceAll('.', ',')}%',
                                  );
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => DcaShareCardPreviewSheet(
                                      result: result,
                                      shareText: text,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.share_outlined),
                                label: Text(l10n.shareResult),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
        },
      ),
    );
  }
}
