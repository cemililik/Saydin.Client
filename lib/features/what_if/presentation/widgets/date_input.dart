import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateInput extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool required;
  final ValueChanged<DateTime?> onChanged;

  const DateInput({
    super.key,
    required this.label,
    this.value,
    this.firstDate,
    this.lastDate,
    this.required = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd.MM.yyyy', 'tr_TR');
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: !required && value != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onChanged(null),
              )
            : null,
      ),
      controller: TextEditingController(
        text: value != null ? formatter.format(value!) : '',
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime(2020),
          firstDate: firstDate ?? DateTime(2010),
          lastDate: lastDate ?? DateTime.now(),
          locale: const Locale('tr', 'TR'),
        );
        onChanged(picked);
      },
    );
  }
}
