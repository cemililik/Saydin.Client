import 'package:flutter/material.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';

class PeriodSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const PeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'weekly', label: Text(l10n.dcaPeriodWeekly)),
        ButtonSegment(value: 'monthly', label: Text(l10n.dcaPeriodMonthly)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }
}
