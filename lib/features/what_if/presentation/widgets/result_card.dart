import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/result_chart.dart';
import 'package:saydin/l10n/app_localizations.dart';

class ResultCard extends StatelessWidget {
  final WhatIfResult result;

  const ResultCard({super.key, required this.result});

  static final _tryFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );
  static final _pctFormatter = NumberFormat.decimalPercentPattern(
    locale: 'tr_TR',
    decimalDigits: 2,
  );
  static final _dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

  /// Küçük sayılar için anlamlı ondalık basamak (kripto, gram vb.)
  static String _formatUnits(double value) {
    if (value == 0) return '0';
    if (value >= 100) return NumberFormat('#,##0.##', 'tr_TR').format(value);
    if (value >= 1) return NumberFormat('#,##0.####', 'tr_TR').format(value);
    return NumberFormat('#,##0.########', 'tr_TR').format(value);
  }

  /// İstenen tarih haftasonuna mı denk geliyor?
  static bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  /// Tarih farklıysa gösterilecek bilgi notu widget'ı
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

  String _formatDuration(AppLocalizations l10n) {
    final end = result.sellDate ?? DateTime.now();
    final days = end.difference(result.buyDate).inDays.abs();
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

    final sellLabel = result.sellDate != null
        ? _dateFormatter.format(result.sellDate!)
        : l10n.today;

    return Card(
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
                        result.isProfit ? l10n.profit : l10n.loss,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${result.assetDisplayName}  •  '
                        '${_dateFormatter.format(result.buyDate)} → $sellLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            ResultChart(result: result),

            const Divider(height: 24),

            // ── Ana metrikler ─────────────────────────────────────────
            _Row(
              l10n.initialValue,
              _tryFormatter.format(result.initialValueTry),
            ),
            _Row(
              l10n.finalValue,
              _tryFormatter.format(result.finalValueTry),
              bold: true,
            ),
            _Row(
              result.isProfit ? l10n.profitLabel : l10n.lossLabel,
              _tryFormatter.format(result.profitLossTry),
              valueColor: color,
            ),
            _Row(
              l10n.profitLossPercent,
              '${result.profitLossPercent >= 0 ? '+' : ''}${_pctFormatter.format(result.profitLossPercent / 100)}',
              valueColor: color,
              bold: true,
            ),

            const Divider(height: 24),

            // ── Detaylar ──────────────────────────────────────────────
            _Row(l10n.resultBuyPrice, _tryFormatter.format(result.buyPrice)),
            _Row(l10n.resultSellPrice, _tryFormatter.format(result.sellPrice)),
            _Row(l10n.resultUnitsAcquired, _formatUnits(result.unitsAcquired)),
            _Row(l10n.resultDuration, _formatDuration(l10n)),

            // ── Tarih ayarlama notları (haftasonu / tatil) ───────────────
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

            // ── Enflasyon düzeltmesi ───────────────────────────────────
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
              _Row(
                l10n.cumulativeInflation,
                '${result.cumulativeInflationPercent! >= 0 ? '+' : ''}'
                '${_pctFormatter.format(result.cumulativeInflationPercent! / 100)}',
              ),
              _Row(
                l10n.realReturn,
                '${result.realProfitLossPercent! >= 0 ? '+' : ''}'
                '${_pctFormatter.format(result.realProfitLossPercent! / 100)}',
                valueColor: result.realProfitLossPercent! >= 0
                    ? AppColors.profit
                    : AppColors.loss,
                bold: true,
              ),
              _Row(
                l10n.realProfitLoss,
                '${result.realProfitLossPercent! >= 0 ? '+' : ''}'
                '${_tryFormatter.format(result.initialValueTry * result.realProfitLossPercent! / 100)}',
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.inflationDataAsOf(
                            _dateFormatter.format(result.inflationDataAsOf!),
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
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _Row(this.label, this.value, {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
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
