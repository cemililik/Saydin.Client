import 'package:flutter/material.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';

class InflationToggle extends StatelessWidget {
  final bool value;
  final bool enabled;
  final VoidCallback onToggle;
  final String? label;

  const InflationToggle({
    super.key,
    required this.value,
    required this.enabled,
    required this.onToggle,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: enabled ? onToggle : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Switch(
              value: enabled ? value : false,
              onChanged: enabled ? (_) => onToggle() : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label ?? l10n.inflationAdjust,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (!enabled) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.premiumFeature,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    l10n.inflationAdjustSubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
