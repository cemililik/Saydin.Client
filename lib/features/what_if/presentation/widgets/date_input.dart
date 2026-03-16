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

  static final _formatter = DateFormat('dd.MM.yyyy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final effectiveFirst = firstDate ?? DateTime(2010);
    final effectiveLast  = lastDate ?? DateTime.now();

    return TextFormField(
      readOnly: true,
      initialValue: value != null ? _formatter.format(value!) : '',
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
      onTap: () async {
        // initialDate'i [firstDate, lastDate] aralığına sıkıştır — runtime exception önler
        final initialDate = value != null
            ? value!.clamp(effectiveFirst, effectiveLast)
            : effectiveLast;

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: effectiveFirst,
          lastDate: effectiveLast,
          locale: const Locale('tr', 'TR'),
        );
        onChanged(picked);
      },
    );
  }
}

extension on DateTime {
  DateTime clamp(DateTime min, DateTime max) {
    if (isBefore(min)) return min;
    if (isAfter(max)) return max;
    return this;
  }
}
