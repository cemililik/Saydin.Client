import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/app_formatters.dart';
import 'package:saydin/core/utils/duration_label.dart';
import 'package:saydin/core/widgets/count_up_text.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/result_chart.dart';
import 'package:saydin/l10n/app_localizations.dart';

class ReverseResultCard extends StatefulWidget {
  final ReverseWhatIfResult result;

  const ReverseResultCard({super.key, required this.result});

  @override
  State<ReverseResultCard> createState() => _ReverseResultCardState();
}

class _ReverseResultCardState extends State<ReverseResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  ReverseWhatIfResult get result => widget.result;

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

  // Locale'e duyarlı formatter'lar — `context.localeName` ile çağrı anında
  // kurulur (static DEĞİL); dil değişiminde TR/EN ayraçları doğru gelir
  // (F-06-01). State.context her zaman geçerli olduğundan instance getter güvenli.
  NumberFormat get _tryFormatter => AppFormat.tryCurrency(context.localeName);
  DateFormat get _dateFormatter => AppFormat.date(context.localeName);

  String _pctSignedFormatter(double v) {
    final sign = v >= 0 ? '+' : '';
    return '$sign${AppFormat.percent(context.localeName).format(v / 100)}';
  }

  String _trySignedFormatter(double v) {
    final sign = v >= 0 ? '+' : '';
    return '$sign${_tryFormatter.format(v)}';
  }

  String _formatUnits(double value) {
    if (value == 0) return '0';
    final locale = context.localeName;
    if (value >= 100) return AppFormat.custom('#,##0.##', locale).format(value);
    if (value >= 1) return AppFormat.custom('#,##0.####', locale).format(value);
    return AppFormat.custom('#,##0.########', locale).format(value);
  }

  static bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  Widget? _buildDateNote(
    AppLocalizations l10n,
    BuildContext context, {
    required DateTime requested,
    required DateTime actual,
    required String label,
  }) {
    final reason = _isWeekend(requested)
        ? l10n.reasonWeekend
        : l10n.reasonHoliday;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.priceDateAdjusted(
                '$label ${_dateFormatter.format(requested)}',
                reason,
                _dateFormatter.format(actual),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ortak [DurationLabel]'a delege (F-07-20).
  String _formatDuration(AppLocalizations l10n) =>
      DurationLabel.format(l10n, result.buyDate, result.sellDate);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = result.isProfit ? AppColors.profit : AppColors.loss;
    final icon = result.isProfit ? Icons.trending_up : Icons.trending_down;

    final sellLabel = result.sellDate != null
        ? _dateFormatter.format(result.sellDate!)
        : l10n.today;

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
                // ── Başlık ────────────────────────────────────────────────
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reverseResultTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${result.assetDisplayName}  •  '
                            '${_dateFormatter.format(result.buyDate)} → $sellLabel',
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

                if (result.priceHistory.isNotEmpty)
                  ResultChart(
                    priceHistory: result.priceHistory,
                    isProfit: result.isProfit,
                  ),

                const Divider(height: 24),

                // ── Ana metrikler ─────────────────────────────────────────
                _AnimatedRow(
                  l10n.requiredInvestment,
                  result.requiredInvestmentTry.toDouble(),
                  formatter: _tryFormatter.format,
                  bold: true,
                ),
                _AnimatedRow(
                  l10n.targetValue,
                  result.targetValueTry.toDouble(),
                  formatter: _tryFormatter.format,
                ),
                _AnimatedRow(
                  result.isProfit ? l10n.profitLabel : l10n.lossLabel,
                  result.profitLossTry.toDouble(),
                  formatter: _tryFormatter.format,
                  valueColor: color,
                ),
                _AnimatedRow(
                  l10n.profitLossPercent,
                  result.profitLossPercent.toDouble(),
                  formatter: _pctSignedFormatter,
                  valueColor: color,
                  bold: true,
                ),

                const Divider(height: 24),

                // ── Detaylar ──────────────────────────────────────────────
                _Row(
                  l10n.resultBuyPrice,
                  _tryFormatter.format(result.buyPrice.toDouble()),
                ),
                _Row(
                  l10n.resultSellPrice,
                  _tryFormatter.format(result.sellPrice.toDouble()),
                ),
                _Row(
                  l10n.resultUnitsAcquired,
                  _formatUnits(result.unitsAcquired.toDouble()),
                ),
                _Row(l10n.resultDuration, _formatDuration(l10n)),

                // ── Tarih ayarlama notları ─────────────────────────────────
                if (result.actualBuyDate != null)
                  _buildDateNote(
                    l10n,
                    context,
                    requested: result.buyDate,
                    actual: result.actualBuyDate!,
                    label: l10n.labelBuyDate,
                  )!,
                if (result.actualSellDate != null)
                  _buildDateNote(
                    l10n,
                    context,
                    requested: result.sellDate ?? DateTime.now(),
                    actual: result.actualSellDate!,
                    label: l10n.labelSellDate,
                  )!,

                // ── Enflasyon düzeltmesi ──────────────────────────────────
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
                  // M2: cumulativeInflationPercent realProfitLossPercent'ten
                  // ayrı/null gelebilir → kendi null-check'i (crash önle).
                  if (result.cumulativeInflationPercent != null)
                    _AnimatedRow(
                      l10n.cumulativeInflation,
                      result.cumulativeInflationPercent!.toDouble(),
                      formatter: _pctSignedFormatter,
                    ),
                  _AnimatedRow(
                    l10n.realReturn,
                    result.realProfitLossPercent!.toDouble(),
                    formatter: _pctSignedFormatter,
                    valueColor: result.realProfitLossPercent! >= 0
                        ? AppColors.profit
                        : AppColors.loss,
                    bold: true,
                  ),
                  _AnimatedRow(
                    l10n.realProfitLoss,
                    // F-07-12: reel kar/zarar TL'si YAKLAŞIK — backend henüz
                    // reel-TL alanı döndürmediği için nominal yatırım × reel
                    // getiri % ile istemcide türetilir (result_card ile aynı
                    // formül). Backend reel-TL alanı eklenince bu çarpım
                    // kaldırılıp alandan okunmalı. Display-only double dönüşüm;
                    // NumberFormat 2 ondalığa yuvarladığından precision farkı yok.
                    result.requiredInvestmentTry.toDouble() *
                        result.realProfitLossPercent! /
                        100,
                    formatter: _trySignedFormatter,
                    valueColor: result.realProfitLossPercent! >= 0
                        ? AppColors.profit
                        : AppColors.loss,
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
