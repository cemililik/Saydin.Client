import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/date_constants.dart';

class DateInput extends StatefulWidget {
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool required;
  final bool enabled;
  final ValueChanged<DateTime?> onChanged;

  const DateInput({
    super.key,
    required this.label,
    this.value,
    this.firstDate,
    this.lastDate,
    this.required = true,
    this.enabled = true,
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
    final hasValidRange = !effectiveFirst.isAfter(effectiveLast);
    final isEnabled = widget.enabled && hasValidRange;

    return TextFormField(
      enabled: isEnabled,
      readOnly: true,
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: isEnabled && !widget.required && widget.value != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => widget.onChanged(null),
              )
            : null,
      ),
      onTap: !isEnabled
          ? null
          : () async {
              // initialDate'i [firstDate, lastDate] aralığına sıkıştır.
              final initialDate = widget.value != null
                  ? widget.value!.clamp(effectiveFirst, effectiveLast)
                  : effectiveLast;

              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: effectiveFirst,
                lastDate: effectiveLast,
                locale: Localizations.localeOf(context),
              );
              if (picked != null) widget.onChanged(picked);
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
