import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/widgets/count_up_text.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';

class PortfolioResultCard extends StatefulWidget {
  final PortfolioResult result;

  const PortfolioResultCard({super.key, required this.result});

  @override
  State<PortfolioResultCard> createState() => _PortfolioResultCardState();
}

class _PortfolioResultCardState extends State<PortfolioResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  PortfolioResult get result => widget.result;

  static final _tryFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = result.isProfit ? AppColors.profit : AppColors.loss;
    final icon = result.isProfit ? Icons.trending_up : Icons.trending_down;

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

                // ── Toplam metrikler (animasyonlu) ──────────────────────
                _AnimatedRow(
                  l10n.portfolioTotalInitial,
                  result.totalInitialValueTry.toDouble(),
                  formatter: _tryFormatter.format,
                ),
                _AnimatedRow(
                  l10n.portfolioTotalFinal,
                  result.totalFinalValueTry.toDouble(),
                  formatter: _tryFormatter.format,
                  bold: true,
                ),
                _AnimatedRow(
                  result.isProfit ? l10n.profitLabel : l10n.lossLabel,
                  result.totalProfitLossTry.toDouble(),
                  formatter: _tryFormatter.format,
                  valueColor: color,
                ),
                _AnimatedRow(
                  l10n.portfolioTotalReturn,
                  result.totalProfitLossPercent.toDouble(),
                  formatter: _pctSignedFormatter,
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
                  _AnimatedRow(
                    l10n.cumulativeInflation,
                    (result.totalCumulativeInflationPercent ?? 0).toDouble(),
                    formatter: _pctSignedFormatter,
                  ),
                  _AnimatedRow(
                    l10n.portfolioRealReturn,
                    (result.totalRealProfitLossPercent ?? 0).toDouble(),
                    formatter: _pctSignedFormatter,
                    valueColor: (result.totalRealProfitLossPercent ?? 0) >= 0
                        ? AppColors.profit
                        : AppColors.loss,
                    bold: true,
                  ),
                  if (result.totalRealProfitLossTry != null)
                    _AnimatedRow(
                      l10n.portfolioRealProfitLoss,
                      (result.totalRealProfitLossTry ?? 0).toDouble(),
                      formatter: _trySignedFormatter,
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
                        final color =
                            AppColors.portfolioColors[i %
                                AppColors.portfolioColors.length];
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
                  final itemSign = item.result.profitLossPercent >= 0
                      ? '+'
                      : '';
                  final pctFmt = NumberFormat.decimalPercentPattern(
                    locale: 'tr_TR',
                    decimalDigits: 2,
                  );

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
                          '$itemSign${pctFmt.format(item.result.profitLossPercent / 100)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
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
        ),
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
