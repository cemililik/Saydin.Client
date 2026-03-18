import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';

class PortfolioResultCard extends StatelessWidget {
  final PortfolioResult result;

  const PortfolioResultCard({super.key, required this.result});

  static final _tryFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );
  static final _pctFormatter = NumberFormat.decimalPercentPattern(
    locale: 'tr_TR',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = result.isProfit ? AppColors.profit : AppColors.loss;
    final icon = result.isProfit ? Icons.trending_up : Icons.trending_down;
    final sign = result.totalProfitLossPercent >= 0 ? '+' : '';

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
                Text(
                  result.isProfit ? l10n.profit : l10n.loss,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // ── Toplam metrikler ──────────────────────────────────────
            _Row(
              l10n.portfolioTotalInitial,
              _tryFormatter.format(result.totalInitialValueTry),
            ),
            _Row(
              l10n.portfolioTotalFinal,
              _tryFormatter.format(result.totalFinalValueTry),
              bold: true,
            ),
            _Row(
              result.isProfit ? l10n.profitLabel : l10n.lossLabel,
              _tryFormatter.format(result.totalProfitLossTry),
              valueColor: color,
            ),
            _Row(
              l10n.portfolioTotalReturn,
              '$sign${_pctFormatter.format(result.totalProfitLossPercent / 100)}',
              valueColor: color,
              bold: true,
            ),

            // Enflasyon bölümü
            if (result.hasInflation) ...[
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
                '${(result.totalCumulativeInflationPercent ?? 0) >= 0 ? '+' : ''}'
                '${_pctFormatter.format((result.totalCumulativeInflationPercent ?? 0) / 100)}',
              ),
              _Row(
                l10n.portfolioRealReturn,
                '${(result.totalRealProfitLossPercent ?? 0) >= 0 ? '+' : ''}'
                '${_pctFormatter.format((result.totalRealProfitLossPercent ?? 0) / 100)}',
                valueColor: (result.totalRealProfitLossPercent ?? 0) >= 0
                    ? AppColors.profit
                    : AppColors.loss,
                bold: true,
              ),
              if (result.totalRealProfitLossTry != null)
                _Row(
                  l10n.portfolioRealProfitLoss,
                  '${(result.totalRealProfitLossTry ?? 0) >= 0 ? '+' : ''}'
                  '${_tryFormatter.format(result.totalRealProfitLossTry ?? 0)}',
                  valueColor: (result.totalRealProfitLossTry ?? 0) >= 0
                      ? AppColors.profit
                      : AppColors.loss,
                ),
            ],

            const Divider(height: 24),

            // ── Pasta grafik ──────────────────────────────────────────
            Text(
              l10n.portfolioChartTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: List.generate(result.items.length, (i) {
                    final item = result.items[i];
                    final color = AppColors
                        .portfolioColors[i % AppColors.portfolioColors.length];
                    return PieChartSectionData(
                      value: item.result.finalValueTry,
                      color: color,
                      title: '${item.sharePercent.toStringAsFixed(1)}%',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      radius: 72,
                    );
                  }),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Varlık bazlı döküm ────────────────────────────────────
            ...List.generate(result.items.length, (i) {
              final item = result.items[i];
              final dotColor = AppColors
                  .portfolioColors[i % AppColors.portfolioColors.length];
              final itemColor = item.result.isProfit
                  ? AppColors.profit
                  : AppColors.loss;
              final itemSign = item.result.profitLossPercent >= 0 ? '+' : '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.item.assetDisplayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '$itemSign${_pctFormatter.format(item.result.profitLossPercent / 100)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: itemColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
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
