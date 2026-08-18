import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/date_constants.dart';

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

  // Sabit sayısal desen — çıktı locale'den bağımsız (gün.ay.yıl, CLAUDE.md).
  // Locale literal'i yok (F-06-01); initState/didUpdateWidget'ta context
  // güvenli olmadığından statik bırakıldı.
  static final _formatter = DateFormat('dd.MM.yyyy');

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
      // Build sırasında controller güncellemesi Form'un setState'ini tetikler;
      // postFrameCallback ile bir sonraki frame'e erteleyerek bunu önlüyoruz.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = widget.value != null
              ? DateInput._formatter.format(widget.value!)
              : '';
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final effectiveFirst = widget.firstDate ?? DateConstants.earliestPriceDate;
    // Date-only normalize: picker tarih bazlı, saat/tz bileşeni taşımasın.
    final effectiveLast =
        widget.lastDate ?? DateTime(now.year, now.month, now.day);

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
          // Takvim UI'ı (ay adları, hafta günleri) aktif dile uysun (F-15-21).
          locale: Localizations.localeOf(context),
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
