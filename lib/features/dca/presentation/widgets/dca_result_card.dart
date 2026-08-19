import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/theme/financial_outcome_style.dart';
import 'package:saydin/core/utils/financial_outcome.dart';
import 'package:saydin/core/utils/app_formatters.dart';
import 'package:saydin/core/utils/duration_label.dart';
import 'package:saydin/core/widgets/count_up_text.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/presentation/widgets/dca_chart.dart';
import 'package:saydin/l10n/app_localizations.dart';

class DcaResultCard extends StatefulWidget {
  final DcaResult result;

  const DcaResultCard({super.key, required this.result});

  @override
  State<DcaResultCard> createState() => _DcaResultCardState();
}

class _DcaResultCardState extends State<DcaResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  DcaResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.localeName;
    if (_cachedLocale != locale) {
      _cachedLocale = locale;
      _tryFormatter = AppFormat.tryCurrency(locale);
      _dateFormatter = AppFormat.date(locale);
      _pctFormatter = AppFormat.percent(locale);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Locale'e duyarlı formatter'lar (F-06-01). CountUpText [formatter]'ı count-up
  // animasyonunda HER frame'de çağırdığından, formatter'lar getter'da yeniden
  // üretilmek yerine didChangeDependencies'te bir kez kurulup önbelleğe alınır;
  // yalnız locale değişince yenilenir (frame başına NumberFormat allocate yok).
  late NumberFormat _tryFormatter;
  late DateFormat _dateFormatter;
  late NumberFormat _pctFormatter;
  String? _cachedLocale;

  String _pctSignedFormatter(double v) {
    final sign = v > 0 ? '+' : '';
    return '$sign${_pctFormatter.format(v / 100)}';
  }

  String _trySignedFormatter(double v) {
    final sign = v > 0 ? '+' : '';
    return '$sign${_tryFormatter.format(v)}';
  }

  String _formatUnits(double value) {
    if (value == 0) return '0';
    final locale = context.localeName;
    if (value >= 100) return AppFormat.custom('#,##0.##', locale).format(value);
    if (value >= 1) return AppFormat.custom('#,##0.####', locale).format(value);
    return AppFormat.custom('#,##0.########', locale).format(value);
  }

  // Ortak [DurationLabel]'a delege (F-07-20).
  String _formatDuration(AppLocalizations l10n) =>
      DurationLabel.format(l10n, result.startDate, result.endDate);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final outcome = result.outcome;
    final color = outcome.color(context);
    final icon = outcome.icon;

    final periodLabel = result.period == 'weekly'
        ? l10n.dcaPeriodWeekly
        : l10n.dcaPeriodMonthly;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            outcome.title(l10n),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${result.assetDisplayName}  •  '
                            '${_dateFormatter.format(result.startDate)} → '
                            '${_dateFormatter.format(result.endDate)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Grafik
                DcaChart(chartData: result.chartData, outcome: outcome),

                const Divider(height: 24),

                // Ana metrikler
                _AnimatedRow(
                  l10n.dcaTotalInvested,
                  result.totalInvestedTry.toDouble(),
                  formatter: _tryFormatter.format,
                ),
                _AnimatedRow(
                  l10n.dcaCurrentValue,
                  result.currentValueTry.toDouble(),
                  formatter: _tryFormatter.format,
                  bold: true,
                ),
                _AnimatedRow(
                  outcome.amountLabel(l10n),
                  result.profitLossTry.toDouble(),
                  formatter: _trySignedFormatter,
                  valueColor: color,
                ),
                _AnimatedRow(
                  l10n.profitLossPercent,
                  result.profitLossPercent,
                  formatter: _pctSignedFormatter,
                  valueColor: color,
                  bold: true,
                ),

                const Divider(height: 24),

                // Detaylar
                _Row(l10n.dcaPeriodLabel, periodLabel),
                _Row(
                  l10n.dcaPeriodicAmount,
                  _tryFormatter.format(result.periodicAmount.toDouble()),
                ),
                _Row(l10n.dcaTotalPurchases, result.totalPurchases.toString()),
                _Row(
                  l10n.dcaAvgCost,
                  _tryFormatter.format(result.averageCostPerUnit.toDouble()),
                ),
                _Row(
                  l10n.dcaTotalUnits,
                  _formatUnits(result.totalUnitsAcquired.toDouble()),
                ),
                _Row(
                  l10n.dcaCurrentPrice,
                  _tryFormatter.format(result.currentUnitPrice.toDouble()),
                ),
                _Row(l10n.resultDuration, _formatDuration(l10n)),

                // Enflasyon düzeltmesi
                if (result.realProfitLossPercent != null ||
                    result.cumulativeInflationPercent != null) ...[
                  const Divider(height: 24),
                  Text(
                    l10n.inflationSectionTitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (result.cumulativeInflationPercent case final value?)
                    _AnimatedRow(
                      l10n.cumulativeInflation,
                      value,
                      formatter: _pctSignedFormatter,
                    ),
                  if (result.realProfitLossPercent case final value?) ...[
                    _AnimatedRow(
                      l10n.realReturn,
                      value,
                      formatter: _pctSignedFormatter,
                      valueColor: FinancialOutcome.fromPercent(
                        value,
                      ).color(context),
                      bold: true,
                    ),
                    // WhatIf result_card.dart ile paralel: reel kar/zarar TL
                    // tutarı (totalInvestedTry * realPct / 100). Sadece percent
                    // göstermek kullanıcıyı "kaç TL kazandım gerçekten?"
                    // sorusuyla baş başa bırakıyordu.
                    _AnimatedRow(
                      l10n.realProfitLoss,
                      result.totalInvestedTry.toDouble() * value / 100,
                      formatter: _trySignedFormatter,
                      valueColor: FinancialOutcome.fromPercent(
                        value,
                      ).color(context),
                    ),
                  ],
                  if (result.inflationDataAsOf != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l10n.inflationDataAsOf(
                                _dateFormatter.format(
                                  result.inflationDataAsOf!,
                                ),
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AnimatedRow extends StatelessWidget {
  final String label;
  final double value;
  final String Function(double) formatter;
  final Color? valueColor;
  final bool bold;

  const _AnimatedRow(
    this.label,
    this.value, {
    required this.formatter,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          CountUpText(
            value: value,
            formatter: formatter,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: bold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
