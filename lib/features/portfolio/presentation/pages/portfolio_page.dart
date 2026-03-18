import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/widgets/settings_icon_button.dart';
import 'package:saydin/core/widgets/inflation_toggle.dart';
import 'package:saydin/core/widgets/share_preview_sheet.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_event.dart';
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_state.dart';
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_add_item_sheet.dart';
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_result_card.dart';
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_share_card_widget.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart';
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart';
import 'package:saydin/features/what_if/presentation/widgets/date_input.dart';
import 'package:saydin/l10n/app_localizations.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PortfolioBloc>().add(const PortfolioAssetsRequested());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showAddSheet(PortfolioState state) {
    final existingSymbols = state.items.map((item) => item.assetSymbol).toSet();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PortfolioAddItemSheet(
        assets: state.assets,
        excludeSymbols: existingSymbols,
        onSave:
            ({
              required assetSymbol,
              required assetDisplayName,
              required amount,
              required amountType,
            }) => context.read<PortfolioBloc>().add(
              PortfolioItemAdded(
                assetSymbol: assetSymbol,
                assetDisplayName: assetDisplayName,
                amount: amount,
                amountType: amountType,
              ),
            ),
      ),
    );
  }

  void _showEditSheet(PortfolioState state, PortfolioItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PortfolioAddItemSheet(
        assets: state.assets,
        editItem: item,
        onSave:
            ({
              required assetSymbol,
              required assetDisplayName,
              required amount,
              required amountType,
            }) => context.read<PortfolioBloc>().add(
              PortfolioItemUpdated(
                id: item.id,
                assetSymbol: assetSymbol,
                assetDisplayName: assetDisplayName,
                amount: amount,
                amountType: amountType,
              ),
            ),
      ),
    );
  }

  void _savePortfolioScenario(PortfolioSuccess state) {
    if (state.buyDate == null) return;
    context.read<ScenariosBloc>().add(
      ScenarioSaveRequested(
        assetSymbol: 'PORTFOLIO',
        assetDisplayName: 'Portföy (${state.items.length} varlık)',
        buyDate: state.buyDate!,
        sellDate: state.sellDate,
        amount: state.result.totalInitialValueTry,
        amountType: 'try',
        type: ScenarioType.portfolio,
        extraData: {
          'totalReturn': state.result.totalProfitLossPercent,
          'includeInflation': state.includeInflation,
          'items': state.items
              .map(
                (item) => {
                  'assetSymbol': item.assetSymbol,
                  'assetDisplayName': item.assetDisplayName,
                  'amount': item.amount,
                  'amountType': item.amountType,
                },
              )
              .toList(),
        },
      ),
    );
  }

  void _showPortfolioShare(PortfolioSuccess state) {
    final sign = state.result.totalProfitLossPercent >= 0 ? '+' : '';
    final pct = state.result.totalProfitLossPercent
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    final shareText =
        'Portföyüm ${state.result.items.length} varlıkla $sign$pct% getiri sağladı! 📊 #saydın';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SharePreviewSheet(
        shareText: shareText,
        cardWidget: PortfolioShareCardWidget(
          result: state.result,
          buyDate: state.buyDate!,
          sellDate: state.sellDate,
        ),
      ),
    );
  }

  void _onCalculate(PortfolioState state) {
    final l10n = context.l10n;
    if (state.buyDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.portfolioBuyDateRequired)));
      return;
    }
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.portfolioMinItems)));
      return;
    }
    context.read<PortfolioBloc>().add(const PortfolioCalculateRequested());
  }

  String _errorMessage(AppError error, AppLocalizations l10n) =>
      switch (error) {
        PriceNotFoundError() => l10n.errorPriceNotFound,
        DailyLimitError() => l10n.errorDailyLimit,
        NoInternetError() => l10n.errorNoInternet,
        ServerError() => l10n.errorServer,
        _ => l10n.errorGeneric,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.portfolioTitle),
        centerTitle: true,
        actions: const [SettingsIconButton()],
      ),
      body: BlocConsumer<PortfolioBloc, PortfolioState>(
        listenWhen: (_, curr) =>
            curr is PortfolioSuccess || curr is PortfolioFailure,
        listener: (context, state) {
          if (state is PortfolioSuccess) {
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
          if (state is PortfolioFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_errorMessage(state.error, context.l10n)),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PortfolioAssetsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final l10n = context.l10n;
          final isCalculating = state is PortfolioCalculating;

          final config = context.read<AppConfigCubit>().state;
          final priceHistoryMonths = config.features.priceHistoryMonths;
          final now = DateTime.now();
          final buyFirstDate = priceHistoryMonths > 0
              ? DateTime(now.year, now.month - priceHistoryMonths, now.day)
              : null;
          final hasDateLimit = priceHistoryMonths > 0 && !config.isPremium;
          final inflationEnabled = config.features.inflationAdjustment;

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Tarih bölümü ─────────────────────────────────────
                Text(
                  l10n.portfolioDateSection,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DateInput(
                  label: l10n.buyDate,
                  value: state.buyDate,
                  firstDate: buyFirstDate,
                  lastDate: now,
                  onChanged: (v) => context.read<PortfolioBloc>().add(
                    PortfolioBuyDateChanged(v),
                  ),
                ),
                if (hasDateLimit) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 13,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l10n.portfolioHistoryLimit(priceHistoryMonths),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                DateInput(
                  label: l10n.sellDate,
                  value: state.sellDate,
                  firstDate: state.buyDate,
                  lastDate: now,
                  required: false,
                  onChanged: (v) => context.read<PortfolioBloc>().add(
                    PortfolioSellDateChanged(v),
                  ),
                ),

                // Enflasyon toggle
                const SizedBox(height: 4),
                InflationToggle(
                  value: state.includeInflation,
                  enabled: inflationEnabled,
                  onToggle: () => context.read<PortfolioBloc>().add(
                    const PortfolioInflationToggled(),
                  ),
                  label: context.l10n.portfolioInflationLabel,
                ),

                const SizedBox(height: 16),

                // ── Varlıklar bölümü ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.portfolioAssetsSection,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: isCalculating
                          ? null
                          : () => _showAddSheet(state),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.portfolioAddAsset),
                    ),
                  ],
                ),

                if (state.items.isEmpty)
                  _EmptyItemsHint(l10n: l10n)
                else
                  ...state.items.map(
                    (item) => _PortfolioItemTile(
                      displayName: item.assetDisplayName,
                      amount: item.amount,
                      amountType: item.amountType,
                      onEdit: isCalculating
                          ? null
                          : () => _showEditSheet(state, item),
                      onRemove: isCalculating
                          ? null
                          : () => context.read<PortfolioBloc>().add(
                              PortfolioItemRemoved(item.id),
                            ),
                    ),
                  ),

                // Kota bilgisi (2+ varlık)
                if (state.items.length > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l10n.portfolioQuotaInfo(state.items.length),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // ── Hesapla / Sıfırla butonları ───────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: isCalculating
                            ? null
                            : () => _onCalculate(state),
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
                        label: Text(
                          isCalculating
                              ? l10n.portfolioCalculating
                              : l10n.portfolioCalculate,
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (state.items.isNotEmpty || state.buyDate != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: isCalculating
                            ? null
                            : () => context.read<PortfolioBloc>().add(
                                const PortfolioReset(),
                              ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(l10n.portfolioReset),
                      ),
                    ],
                  ],
                ),

                // ── Sonuç kartı ───────────────────────────────────────
                if (state is PortfolioSuccess) ...[
                  const SizedBox(height: 24),
                  PortfolioResultCard(result: state.result),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.buyDate != null
                              ? () => _savePortfolioScenario(state)
                              : null,
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
                          onPressed: state.buyDate != null
                              ? () => _showPortfolioShare(state)
                              : null,
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
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Yardımcı widget'lar ────────────────────────────────────────────────────────

class _EmptyItemsHint extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyItemsHint({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.portfolioEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.portfolioEmptyHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PortfolioItemTile extends StatelessWidget {
  final String displayName;
  final num amount;
  final String amountType;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const _PortfolioItemTile({
    required this.displayName,
    required this.amount,
    required this.amountType,
    this.onEdit,
    this.onRemove,
  });

  static final _tryFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  String _formatAmount(BuildContext context) {
    final l10n = context.l10n;
    return switch (amountType) {
      'try' => _tryFormatter.format(amount),
      'units' =>
        '${NumberFormat('#,##0.####', 'tr_TR').format(amount)} ${l10n.amountTypeUnits}',
      'grams' =>
        '${NumberFormat('#,##0.####', 'tr_TR').format(amount)} ${l10n.amountTypeGrams}',
      _ => amount.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: const Icon(Icons.bar_chart),
          title: Text(displayName),
          subtitle: Text(_formatAmount(context)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
            ],
          ),
        ),
      ),
    );
  }
}
