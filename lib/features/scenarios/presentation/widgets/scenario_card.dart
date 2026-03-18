import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

class ScenarioCard extends StatelessWidget {
  final SavedScenario scenario;
  final VoidCallback? onTap;

  const ScenarioCard({super.key, required this.scenario, this.onTap});

  @override
  Widget build(BuildContext context) {
    return switch (scenario.type) {
      ScenarioType.whatIf => _WhatIfCard(scenario: scenario, onTap: onTap),
      ScenarioType.comparison => _ComparisonCard(
        scenario: scenario,
        onTap: onTap,
      ),
      ScenarioType.portfolio => _PortfolioCard(
        scenario: scenario,
        onTap: onTap,
      ),
    };
  }
}

// ── Ortak yardımcılar ─────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _TypeChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

Widget _dateRow(BuildContext context, String label) {
  final theme = Theme.of(context);
  return Row(
    children: [
      Icon(
        Icons.calendar_today_outlined,
        size: 12,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

// ── WhatIf kartı ─────────────────────────────────────────────────────────────

class _WhatIfCard extends StatelessWidget {
  final SavedScenario scenario;
  final VoidCallback? onTap;

  const _WhatIfCard({required this.scenario, this.onTap});

  static final _tryFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );
  static final _dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

  String _formatAmount() {
    if (scenario.amountType == 'try') {
      return _tryFormatter.format(scenario.amount);
    }
    final suffix = scenario.amountType == 'grams' ? 'gram' : 'adet';
    return '${NumberFormat.decimalPattern('tr_TR').format(scenario.amount)} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final buyLabel = _dateFormatter.format(scenario.buyDate);
    final sellLabel = scenario.sellDate != null
        ? _dateFormatter.format(scenario.sellDate!)
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scenario.assetDisplayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: l10n.scenarioTypeWhatIf,
                          bgColor: Colors.blue.shade50,
                          textColor: Colors.blue.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _dateRow(context, '$buyLabel → $sellLabel'),
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
                          _formatAmount(),
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
}

// ── Karşılaştırma kartı ───────────────────────────────────────────────────────

class _ComparisonCard extends StatelessWidget {
  final SavedScenario scenario;
  final VoidCallback? onTap;

  const _ComparisonCard({required this.scenario, this.onTap});

  static final _dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final buyLabel = _dateFormatter.format(scenario.buyDate);
    final sellLabel = scenario.sellDate != null
        ? _dateFormatter.format(scenario.sellDate!)
        : l10n.today;

    final winnerName = scenario.extraData?['winnerName'] as String? ?? '';
    final winnerReturn =
        (scenario.extraData?['winnerReturn'] as num?)?.toDouble() ?? 0.0;
    final winnerSign = winnerReturn >= 0 ? '+' : '';
    final winnerColor = winnerReturn >= 0 ? AppColors.profit : AppColors.loss;

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
                backgroundColor: Colors.purple.shade50,
                child: Icon(
                  Icons.compare_arrows,
                  color: Colors.purple.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scenario.assetDisplayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: l10n.scenarioTypeComparison,
                          bgColor: Colors.purple.shade50,
                          textColor: Colors.purple.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _dateRow(context, '$buyLabel → $sellLabel'),
                    if (winnerName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Text('🥇 ', style: TextStyle(fontSize: 12)),
                          Expanded(
                            child: Text(
                              '$winnerName  $winnerSign${winnerReturn.toStringAsFixed(2).replaceAll('.', ',')}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: winnerColor,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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
}

// ── Portföy kartı ─────────────────────────────────────────────────────────────

class _PortfolioCard extends StatelessWidget {
  final SavedScenario scenario;
  final VoidCallback? onTap;

  const _PortfolioCard({required this.scenario, this.onTap});

  static final _tryFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 0,
  );
  static final _dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final buyLabel = _dateFormatter.format(scenario.buyDate);
    final sellLabel = scenario.sellDate != null
        ? _dateFormatter.format(scenario.sellDate!)
        : l10n.today;

    final totalReturn =
        (scenario.extraData?['totalReturn'] as num?)?.toDouble() ?? 0.0;
    final returnSign = totalReturn >= 0 ? '+' : '';
    final returnColor = totalReturn >= 0 ? AppColors.profit : AppColors.loss;

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
                backgroundColor: Colors.teal.shade50,
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.teal.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            scenario.assetDisplayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: l10n.scenarioTypePortfolio,
                          bgColor: Colors.teal.shade50,
                          textColor: Colors.teal.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _dateRow(context, '$buyLabel → $sellLabel'),
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
                          _tryFormatter.format(scenario.amount),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (totalReturn != 0.0) ...[
                          Text(
                            '  •  ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '$returnSign${totalReturn.toStringAsFixed(2).replaceAll('.', ',')}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: returnColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
}
