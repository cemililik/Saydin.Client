import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static final _tryFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );
  static final _dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

  static String _pctSignedFormatter(double v) {
    final sign = v >= 0 ? '+' : '';
    final fmt = NumberFormat.decimalPercentPattern(
      locale: 'tr_TR',
      decimalDigits: 2,
    );
    return '$sign${fmt.format(v / 100)}';
  }

  static String _trySignedFormatter(double v) {
    final sign = v >= 0 ? '+' : '';
    return '$sign${_tryFormatter.format(v)}';
  }

  static String _formatUnits(double value) {
    if (value == 0) return '0';
    if (value >= 100) return NumberFormat('#,##0.##', 'tr_TR').format(value);
    if (value >= 1) return NumberFormat('#,##0.####', 'tr_TR').format(value);
    return NumberFormat('#,##0.########', 'tr_TR').format(value);
  }

  String _formatDuration(AppLocalizations l10n) {
    final days = result.endDate.difference(result.startDate).inDays.abs();
    if (days < 30) return l10n.durationDays(days);
    if (days < 365) return l10n.durationMonths(days ~/ 30);
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    return months > 0
        ? l10n.durationYearsMonths(years, months)
        : l10n.durationYears(years);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = result.isProfit ? AppColors.profit : AppColors.loss;
    final icon = result.isProfit ? Icons.trending_up : Icons.trending_down;

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
                            result.isProfit ? l10n.profit : l10n.loss,
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
                DcaChart(
                  chartData: result.chartData,
                  isProfit: result.isProfit,
                ),

                const Divider(height: 24),

                // Ana metrikler
                _AnimatedRow(
                  l10n.dcaTotalInvested,
                  result.totalInvestedTry,
                  formatter: _tryFormatter.format,
                ),
                _AnimatedRow(
                  l10n.dcaCurrentValue,
                  result.currentValueTry,
                  formatter: _tryFormatter.format,
                  bold: true,
                ),
                _AnimatedRow(
                  result.isProfit ? l10n.profitLabel : l10n.lossLabel,
                  result.profitLossTry,
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
                  _tryFormatter.format(result.periodicAmount),
                ),
                _Row(l10n.dcaTotalPurchases, result.totalPurchases.toString()),
                _Row(
                  l10n.dcaAvgCost,
                  _tryFormatter.format(result.averageCostPerUnit),
                ),
                _Row(
                  l10n.dcaTotalUnits,
                  _formatUnits(result.totalUnitsAcquired),
                ),
                _Row(
                  l10n.dcaCurrentPrice,
                  _tryFormatter.format(result.currentUnitPrice),
                ),
                _Row(l10n.resultDuration, _formatDuration(l10n)),

                // Enflasyon düzeltmesi
                if (result.realProfitLossPercent != null) ...[
                  const Divider(height: 24),
                  Text(
                    l10n.inflationSectionTitle,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AnimatedRow(
                    l10n.cumulativeInflation,
                    result.cumulativeInflationPercent!,
                    formatter: _pctSignedFormatter,
                  ),
                  _AnimatedRow(
                    l10n.realReturn,
                    result.realProfitLossPercent!,
                    formatter: _pctSignedFormatter,
                    valueColor: result.realProfitLossPercent! >= 0
                        ? AppColors.profit
                        : AppColors.loss,
                    bold: true,
                  ),
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
