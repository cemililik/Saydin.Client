import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateInput extends StatefulWidget {
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
  State<DateInput> createState() => _DateInputState();
}

class _DateInputState extends State<DateInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value != null
          ? DateInput._formatter.format(widget.value!)
          : '',
    );
  }

  @override
  void didUpdateWidget(DateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value != null
          ? DateInput._formatter.format(widget.value!)
          : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFirst = widget.firstDate ?? DateTime(2010);
    final effectiveLast = widget.lastDate ?? DateTime.now();

    return TextFormField(
      readOnly: true,
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: !widget.required && widget.value != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => widget.onChanged(null),
              )
            : null,
      ),
      onTap: () async {
        // initialDate'i [firstDate, lastDate] aralığına sıkıştır — runtime exception önler
        final initialDate = widget.value != null
            ? widget.value!.clamp(effectiveFirst, effectiveLast)
            : effectiveLast;

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: effectiveFirst,
          lastDate: effectiveLast,
          locale: const Locale('tr', 'TR'),
        );
        widget.onChanged(picked);
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
