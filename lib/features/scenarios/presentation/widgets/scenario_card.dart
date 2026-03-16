import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

class ScenarioCard extends StatelessWidget {
  final SavedScenario scenario;
  final VoidCallback? onTap;

  const ScenarioCard({super.key, required this.scenario, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

    final buyLabel = dateFormatter.format(scenario.buyDate);
    final sellLabel = scenario.sellDate != null
        ? dateFormatter.format(scenario.sellDate!)
        : l10n.today;

    final rawSymbol = scenario.assetSymbol.replaceAll(RegExp(r'TRY$'), '');
    final avatarText = rawSymbol
        .substring(0, min(3, rawSymbol.length))
        .toUpperCase();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  avatarText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: avatarText.length > 2 ? 10 : 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.assetDisplayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$buyLabel → $sellLabel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatAmount(scenario.amount, scenario.amountType),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(num amount, String amountType) {
    if (amountType == 'try') {
      return NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '₺',
        decimalDigits: 2,
      ).format(amount);
    }
    final suffix = amountType == 'grams' ? 'gram' : 'adet';
    return '${NumberFormat.decimalPattern('tr_TR').format(amount)} $suffix';
  }
}
