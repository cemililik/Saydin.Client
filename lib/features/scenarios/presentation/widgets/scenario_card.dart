import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/percentage_formatter.dart';
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
      ScenarioType.dca => _DcaCard(scenario: scenario, onTap: onTap),
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

final _savedAtFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

/// F-11-04: Kartta gösterilen getiri/yüzde değerleri kayıt anına ait SABİT
/// bir snapshot'tır (güncel piyasa değeri değil). Kayıt tarihi + "o günkü
/// sonuç" uyarısı bunu kullanıcıya açıkça belirtir.
Widget _savedAtRow(BuildContext context, DateTime createdAt) {
  final theme = Theme.of(context);
  return Row(
    children: [
      Icon(
        Icons.history_outlined,
        size: 12,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          context.l10n.scenarioSavedAtSnapshot(
            _savedAtFormatter.format(createdAt),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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

  String _formatAmount(BuildContext context) {
    final l10n = context.l10n;
    final amount = scenario.amount.toDouble();
    if (scenario.amountType == 'try') {
      return _tryFormatter.format(amount);
    }
    final suffix = scenario.amountType == 'grams'
        ? l10n.amountTypeGrams
        : l10n.amountTypeUnits;
    return '${NumberFormat.decimalPattern('tr_TR').format(amount)} $suffix';
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
                            // Kayıt anındaki donmuş ad (snapshot). Canlı
                            // WhatIfBloc lookup'ı kaldırıldı — Scenarios artık
                            // What-If'e bağlı değil (F-11-07). Senaryo geçmişsel
                            // olduğu için ad da kayıt anına sabittir.
                            scenario.assetDisplayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: scenario.extraData?['mode'] == 'reverse'
                              ? l10n.scenarioTypeReverse
                              : l10n.scenarioTypeWhatIf,
                          bgColor: scenario.extraData?['mode'] == 'reverse'
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          textColor: scenario.extraData?['mode'] == 'reverse'
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _dateRow(context, '$buyLabel → $sellLabel'),
                    const SizedBox(height: 3),
                    _savedAtRow(context, scenario.createdAt),
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
                          _formatAmount(context),
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

// ── DCA kartı ────────────────────────────────────────────────────────────────

class _DcaCard extends StatelessWidget {
  final SavedScenario scenario;
  final VoidCallback? onTap;

  const _DcaCard({required this.scenario, this.onTap});

  static final _tryFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
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
    final period = scenario.extraData?['period'] as String? ?? 'monthly';
    final periodLabel = period == 'weekly'
        ? l10n.dcaPeriodWeekly
        : l10n.dcaPeriodMonthly;

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
                backgroundColor: Colors.orange.shade50,
                child: Icon(
                  Icons.repeat,
                  color: Colors.orange.shade600,
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
                            // Snapshot ad — bkz. F-11-07 (WhatIfBloc bağı yok).
                            scenario.assetDisplayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TypeChip(
                          label: l10n.scenarioTypeDca,
                          bgColor: Colors.orange.shade50,
                          textColor: Colors.orange.shade700,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _dateRow(context, '$buyLabel → $sellLabel'),
                    const SizedBox(height: 3),
                    _savedAtRow(context, scenario.createdAt),
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
                          '${_tryFormatter.format(scenario.amount.toDouble())} / $periodLabel',
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

    // Sembol sayısından lokalize başlık oluştur
    final symbolCount = scenario.assetSymbol.split(',').length;
    final title = l10n.scenarioNameComparison(symbolCount);

    // Kazanan adı kayıt anında extraData'ya yazılan snapshot'tır; canlı
    // WhatIfBloc lookup'ı kaldırıldı (F-11-07 — Scenarios → What-If bağı yok).
    // Defansif okuma (PR geneli `is` paterni): non-String/non-num bir değer
    // gelirse `as` cast TypeError atıp kartı çökertirdi.
    final winnerVal = scenario.extraData?['winnerName'];
    final winnerName = winnerVal is String ? winnerVal : '';
    final winnerReturnVal = scenario.extraData?['winnerReturn'];
    final winnerReturn = winnerReturnVal is num
        ? winnerReturnVal.toDouble()
        : 0.0;
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
                            title,
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
                    const SizedBox(height: 3),
                    _savedAtRow(context, scenario.createdAt),
                    if (winnerName.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Text('🥇 ', style: TextStyle(fontSize: 12)),
                          // CLAUDE.md a11y kuralı: kar/zarar sadece renkle
                          // gösterilmez — ikon eşlik etmeli (renk körü).
                          Icon(
                            winnerReturn >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 12,
                            color: winnerColor,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '$winnerName  ${PercentageFormatter.signed(winnerReturn)}',
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

    // Varlık sayısından lokalize başlık oluştur
    final rawItems = scenario.extraData?['items'] as List<dynamic>? ?? [];
    final title = l10n.scenarioNamePortfolio(rawItems.length);

    final totalReturn =
        (scenario.extraData?['totalReturn'] as num?)?.toDouble() ?? 0.0;
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
                            title,
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
                    _savedAtRow(context, scenario.createdAt),
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
                          _tryFormatter.format(scenario.amount.toDouble()),
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
                          // CLAUDE.md a11y: kar/zarar ikon eşliğinde.
                          Icon(
                            totalReturn >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 12,
                            color: returnColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            PercentageFormatter.signed(totalReturn),
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
