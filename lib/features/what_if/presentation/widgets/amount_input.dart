import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';

class AmountInput extends StatelessWidget {
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

    final items = allowedTypes
        .where(allItems.containsKey)
        .map((t) => DropdownMenuItem(value: t, child: Text(allItems[t]!)))
        .toList();

    final effectiveType = allowedTypes.contains(amountType)
        ? amountType
        : allowedTypes.first;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: InputDecoration(
              labelText: labelOverride ?? l10n.amount,
              border: const OutlineInputBorder(),
              prefixIcon: _prefixIcon(effectiveType),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? (validatorOverride ?? l10n.enterAmount)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            key: ValueKey('$effectiveType-${allowedTypes.join()}'),
            initialValue: effectiveType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: items,
            onChanged: (v) => v != null ? onAmountTypeChanged(v) : null,
          ),
        ),
      ],
    );
  }
}
