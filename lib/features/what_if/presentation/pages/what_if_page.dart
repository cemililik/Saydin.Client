import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
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

class WhatIfPage extends StatefulWidget {
  const WhatIfPage({super.key});

  @override
  State<WhatIfPage> createState() => _WhatIfPageState();
}

class _WhatIfPageState extends State<WhatIfPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<WhatIfBloc>().add(const WhatIfAssetsRequested());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    final formInput = context.read<WhatIfBloc>().state.formInput;

    if (formInput.selectedSymbol == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.assetRequired)));
      return;
    }
    if (formInput.buyDate == null) {
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
        assetSymbol: formInput.selectedSymbol!,
        buyDate: formInput.buyDate!,
        sellDate: formInput.sellDate,
        amount: amount,
        amountType: formInput.amountType,
      ),
    );
  }

  String _errorMessage(AppError error, AppLocalizations l10n) =>
      switch (error) {
        PriceNotFoundError() => l10n.errorPriceNotFound,
        DailyLimitError() => l10n.errorDailyLimit,
        NoInternetError() => l10n.errorNoInternet,
        ServerError() => l10n.errorServer,
        UnknownError() => l10n.errorGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.whatIfTitle), centerTitle: true),
      body: BlocConsumer<WhatIfBloc, WhatIfState>(
        listener: (context, state) {
          if (state is WhatIfFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_errorMessage(state.error, context.l10n)),
                backgroundColor: Colors.red.shade700,
              ),
            );
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
          return _WhatIfForm(
            formKey: _formKey,
            assets: assets,
            selectedSymbol: formInput.selectedSymbol,
            buyDate: formInput.buyDate,
            sellDate: formInput.sellDate,
            amountType: formInput.amountType,
            amountController: _amountController,
            isCalculating: state is WhatIfCalculating,
            result: state is WhatIfSuccess ? state.result : null,
            onAssetChanged: (v) =>
                context.read<WhatIfBloc>().add(WhatIfSymbolChanged(v)),
            onBuyDateChanged: (v) =>
                context.read<WhatIfBloc>().add(WhatIfBuyDateChanged(v)),
            onSellDateChanged: (v) =>
                context.read<WhatIfBloc>().add(WhatIfSellDateChanged(v)),
            onAmountTypeChanged: (v) =>
                context.read<WhatIfBloc>().add(WhatIfAmountTypeChanged(v)),
            onCalculate: _onCalculate,
          );
        },
      ),
    );
  }
}

class _WhatIfForm extends StatelessWidget {
  const _WhatIfForm({
    required this.formKey,
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
  });

  final GlobalKey<FormState> formKey;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
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
              lastDate: DateTime.now(),
              onChanged: onBuyDateChanged,
            ),
            const SizedBox(height: 16),
            DateInput(
              label: l10n.sellDate,
              value: sellDate,
              firstDate: buyDate,
              lastDate: DateTime.now(),
              required: false,
              onChanged: onSellDateChanged,
            ),
            const SizedBox(height: 16),
            AmountInput(
              controller: amountController,
              amountType: amountType,
              onAmountTypeChanged: onAmountTypeChanged,
            ),
            const SizedBox(height: 24),
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
            if (result != null) ...[
              const SizedBox(height: 24),
              ResultCard(result: result!),
            ],
          ],
        ),
      ),
    );
  }
}
