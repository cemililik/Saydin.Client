import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String amountType;
  final ValueChanged<String> onAmountTypeChanged;

  const AmountInput({
    super.key,
    required this.controller,
    required this.amountType,
    required this.onAmountTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              labelText: l10n.amount,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? l10n.enterAmount : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            key: ValueKey(amountType),
            initialValue: amountType,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(value: 'try', child: Text(l10n.amountTypeTry)),
              DropdownMenuItem(
                value: 'units',
                child: Text(l10n.amountTypeUnits),
              ),
              DropdownMenuItem(
                value: 'grams',
                child: Text(l10n.amountTypeGrams),
              ),
            ],
            onChanged: (v) => v != null ? onAmountTypeChanged(v) : null,
          ),
        ),
      ],
    );
  }
}
