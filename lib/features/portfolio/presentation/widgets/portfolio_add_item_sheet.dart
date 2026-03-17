import 'package:flutter/material.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/presentation/widgets/amount_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/asset_selector.dart';

class PortfolioAddItemSheet extends StatefulWidget {
  final List<Asset> assets;
  final void Function({
    required String assetSymbol,
    required String assetDisplayName,
    required num amount,
    required String amountType,
  })
  onAdd;

  const PortfolioAddItemSheet({
    super.key,
    required this.assets,
    required this.onAdd,
  });

  @override
  State<PortfolioAddItemSheet> createState() => _PortfolioAddItemSheetState();
}

class _PortfolioAddItemSheetState extends State<PortfolioAddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedSymbol;
  String _amountType = 'try';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Asset? get _selectedAsset =>
      widget.assets.where((a) => a.symbol == _selectedSymbol).firstOrNull;

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedSymbol == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.assetRequired)));
      return;
    }
    final amount = num.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.validAmountRequired)));
      return;
    }
    widget.onAdd(
      assetSymbol: _selectedSymbol!,
      assetDisplayName: _selectedAsset?.displayName ?? _selectedSymbol!,
      amount: amount,
      amountType: _amountType,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final allowedTypes = _selectedAsset?.allowedAmountTypes ?? const ['try'];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              l10n.portfolioAddAssetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            AssetSelector(
              assets: widget.assets,
              selectedSymbol: _selectedSymbol,
              onChanged: (v) => setState(() {
                _selectedSymbol = v;
                _amountType = 'try';
              }),
            ),
            const SizedBox(height: 12),

            AmountInput(
              controller: _amountController,
              amountType: _amountType,
              allowedTypes: allowedTypes,
              onAmountTypeChanged: (v) => setState(() => _amountType = v),
            ),
            const SizedBox(height: 16),

            FilledButton(
              onPressed: _submit,
              child: Text(l10n.portfolioAddAsset),
            ),
          ],
        ),
      ),
    );
  }
}
