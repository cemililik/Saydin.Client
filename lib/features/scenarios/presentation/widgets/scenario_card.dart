import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

class ScenarioCard extends StatelessWidget {
  final SavedScenario scenario;
  final VoidCallback onDelete;

  const ScenarioCard({
    super.key,
    required this.scenario,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');
    final sellDateLabel = scenario.sellDate != null
        ? dateFormatter.format(scenario.sellDate!)
        : l10n.today;

    final amountLabel = _formatAmount(scenario.amount, scenario.amountType);

    return Card(
      child: ListTile(
        title: Text(
          scenario.assetDisplayName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${dateFormatter.format(scenario.buyDate)} → $sellDateLabel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(amountLabel, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 2),
            Text(
              dateFormatter.format(scenario.createdAt.toLocal()),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          color: Colors.red,
          onPressed: onDelete,
          tooltip: l10n.deleteScenario,
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatAmount(num amount, String amountType) {
    if (amountType == 'try') {
      final formatter = NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '₺',
        decimalDigits: 2,
      );
      return formatter.format(amount);
    }
    final formatter = NumberFormat.decimalPattern('tr_TR');
    return '${formatter.format(amount)} $amountType';
  }
}
