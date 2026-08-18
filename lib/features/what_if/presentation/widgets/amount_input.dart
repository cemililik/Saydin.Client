import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/locale_number_parser.dart';

class AmountInput extends StatefulWidget {
  final TextEditingController controller;
  final String amountType;
  final List<String> allowedTypes;
  final ValueChanged<String> onAmountTypeChanged;
  final String? labelOverride;
  final String? validatorOverride;

  const AmountInput({
    super.key,
    required this.controller,
    required this.amountType,
    required this.allowedTypes,
    required this.onAmountTypeChanged,
    this.labelOverride,
    this.validatorOverride,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  String? _previousLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.localeName;
    final previousLocale = _previousLocale;
    if (previousLocale != null && previousLocale != locale) {
      final reformatted = LocaleNumberParser.reformatInput(
        widget.controller.text,
        fromLocale: previousLocale,
        toLocale: locale,
      );
      if (reformatted != widget.controller.text) {
        widget.controller.value = TextEditingValue(
          text: reformatted,
          selection: TextSelection.collapsed(offset: reformatted.length),
        );
      }
    }
    _previousLocale = locale;
  }

  Widget _prefixIcon(String type) => switch (type) {
    'grams' => const Icon(Icons.scale_outlined),
    'units' => const Icon(Icons.tag),
    _ => const Icon(Icons.currency_lira),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final allItems = {
      'try': l10n.amountTypeTry,
      'units': l10n.amountTypeUnits,
      'grams': l10n.amountTypeGrams,
    };

    final items = widget.allowedTypes
        .where(allItems.containsKey)
        .map((t) => DropdownMenuItem(value: t, child: Text(allItems[t]!)))
        .toList();

    final effectiveType = widget.allowedTypes.contains(widget.amountType)
        ? widget.amountType
        : widget.allowedTypes.first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: widget.controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: InputDecoration(
              labelText: widget.labelOverride ?? l10n.amount,
              border: const OutlineInputBorder(),
              prefixIcon: _prefixIcon(effectiveType),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? (widget.validatorOverride ?? l10n.enterAmount)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            key: ValueKey('$effectiveType-${widget.allowedTypes.join()}'),
            initialValue: effectiveType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: items,
            onChanged: (v) =>
                v != null ? widget.onAmountTypeChanged(v) : null,
          ),
        ),
      ],
    );
  }
}
