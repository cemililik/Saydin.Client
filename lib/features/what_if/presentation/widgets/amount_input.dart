import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d*')),
            ],
            decoration: const InputDecoration(
              labelText: 'Tutar',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Tutar giriniz' : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            key: ValueKey(amountType),
            initialValue: amountType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'try', child: Text('₺ TL')),
              DropdownMenuItem(value: 'units', child: Text('Adet')),
              DropdownMenuItem(value: 'grams', child: Text('Gram')),
            ],
            onChanged: (v) => v != null ? onAmountTypeChanged(v) : null,
          ),
        ),
      ],
    );
  }
}
