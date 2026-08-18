import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/locale_number_parser.dart';
import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/portfolio_constants.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/presentation/widgets/amount_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/asset_selector.dart';

/// Portföye varlık ekleme veya düzenleme sayfası.
/// [editItem] verilirse düzenleme modunda açılır.
class PortfolioAddItemSheet extends StatefulWidget {
  final List<Asset> assets;

  /// Düzenleme modunda pre-fill için mevcut kalem; null ise ekleme modu.
  final PortfolioItem? editItem;

  /// Listeden gizlenecek semboller (portföyde zaten eklenmiş varlıklar).
  final Set<String> excludeSymbols;

  final void Function({
    required String assetSymbol,
    required String assetDisplayName,
    required num amount,
    required String amountType,
  })
  onSave;

  const PortfolioAddItemSheet({
    super.key,
    required this.assets,
    required this.onSave,
    this.editItem,
    this.excludeSymbols = const {},
  });

  @override
  State<PortfolioAddItemSheet> createState() => _PortfolioAddItemSheetState();
}

class _PortfolioAddItemSheetState extends State<PortfolioAddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  late String? _selectedSymbol;
  late String _amountType;

  // Düzenleme ön-doldurması yalnızca bir kez yapılır — didChangeDependencies
  // birden çok kez tetiklenebilir; kullanıcı girişini ezmemek için guard.
  bool _didPrefill = false;

  bool get _isEditMode => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.editItem;
    _selectedSymbol = edit?.assetSymbol;
    _amountType = edit?.amountType ?? 'try';
    _amountController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Düzenleme ön-doldurması locale-duyarlı olmalı: EN'de '1234.56', TR'de
    // '1234,56'. didChangeDependencies ilk build'den ÖNCE ve Localizations
    // hazırken çalışır; postFrame gibi ilk kareyi boş gösterip sonra doldurmaz
    // (flicker yok). Guard ile yalnız bir kez çalışır, kullanıcı girişini ezmez.
    final edit = widget.editItem;
    if (edit != null && !_didPrefill) {
      _didPrefill = true;
      _amountController.text = LocaleNumberParser.formatForInput(
        edit.amount.toDouble(),
        context.localeName,
      );
    }
  }

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
    final l10n = context.l10n;
    final amount = LocaleNumberParser.tryParse(
      _amountController.text,
      context.localeName,
    );
    // null / NaN / Infinity (isFinite hepsini eler) / <=0 reddet.
    if (amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.validAmountRequired)));
      return;
    }
    // Üst sınır: astronomik girişleri (aggregasyon + quota) engelle.
    if (amount > PortfolioConstants.maxItemAmount) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.portfolioAmountTooLarge)));
      return;
    }
    // Ondalık hane sınırı: TL kuruş (2), birim/gram (4). Decimal.toString()
    // kanonik '.' ayraç kullanır (binlik yok) → güvenilir hane sayımı.
    final maxDecimals = _amountType == 'try' ? 2 : 4;
    final decStr = (MoneyParser.tryDecimal(amount) ?? Decimal.zero).toString();
    final dotIdx = decStr.indexOf('.');
    final decimalCount = dotIdx >= 0 ? decStr.length - dotIdx - 1 : 0;
    if (decimalCount > maxDecimals) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.portfolioAmountTooManyDecimals(maxDecimals)),
        ),
      );
      return;
    }
    widget.onSave(
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
              _isEditMode
                  ? l10n.portfolioEditAssetTitle
                  : l10n.portfolioAddAssetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            AssetSelector(
              assets: widget.assets,
              selectedSymbol: _selectedSymbol,
              excludeSymbols: widget.excludeSymbols,
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
              child: Text(
                _isEditMode ? l10n.portfolioSaveAsset : l10n.portfolioAddAsset,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
