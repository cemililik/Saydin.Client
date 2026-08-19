import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/error/app_error_messages.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/theme/financial_colors.dart';
import 'package:saydin/core/theme/financial_outcome_style.dart';
import 'package:saydin/core/utils/financial_outcome.dart';
import 'package:saydin/core/utils/app_formatters.dart';
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

  // Locale'e duyarlı formatter'lar (F-06-01). CountUpText [formatter]'ı count-up
  // animasyonunda HER frame'de çağırdığından, formatter'lar getter'da yeniden
  // üretilmek yerine didChangeDependencies'te bir kez kurulup önbelleğe alınır;
  // yalnız locale değişince yenilenir (frame başına NumberFormat allocate yok).
  late NumberFormat _tryFormatter;
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
      _pctFormatter = AppFormat.percent(locale);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final financialColors = context.financialColors;
    final outcome = result.outcome;
    final color = outcome.color(context);
    final icon = outcome.icon;

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
                if (result.hasPartialFailure) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.portfolioPartialResult,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.portfolioPartialResultDetail,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                        ),
                        const SizedBox(height: 6),
                        ...result.failures.map(
                          (failure) => Text(
                            '\u2022 ${failure.item.assetDisplayName}: '
                            '${failure.error.localizedMessage(l10n)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // ── Başlık ────────────────────────────────────────────────
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      outcome.title(l10n),
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
                  outcome.amountLabel(l10n),
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
                    valueColor: FinancialOutcome.fromPercent(
                      result.totalRealProfitLossPercent ?? 0,
                    ).color(context),
                    bold: true,
                  ),
                  if (result.totalRealProfitLossTry != null)
                    _AnimatedRow(
                      l10n.portfolioRealProfitLoss,
                      result.totalRealProfitLossTry!.toDouble(),
                      formatter: _trySignedFormatter,
                      valueColor: FinancialOutcome.fromAmount(
                        result.totalRealProfitLossTry!,
                      ).color(context),
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

                Semantics(
                  container: true,
                  image: true,
                  label: l10n.portfolioChartTitle,
                  child: ExcludeSemantics(
                    child: SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: List.generate(result.items.length, (i) {
                            final item = result.items[i];
                            final palette = financialColors.portfolioPalette;
                            final color = palette[i % palette.length];
                            return PieChartSectionData(
                              // fl_chart double ister; pasta dilimi oranı zaten
                              // floating-point ile temsil ediliyor — finansal
                              // toplama Decimal'da yapıldı.
                              value: item.calculation.finalValueTry.toDouble(),
                              color: color,
                              // F-11-16: locale-aware yüzde (manuel '%' yerine).
                              title: AppFormat.percent(
                                context.localeName,
                                decimalDigits: 1,
                              ).format(item.sharePercent / 100),
                              titleStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    ThemeData.estimateBrightnessForColor(
                                          color,
                                        ) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              radius: 72,
                            );
                          }),
                          sectionsSpace: 2,
                          centerSpaceRadius: 0,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Varlık bazlı döküm ────────────────────────────────────
                ...List.generate(result.items.length, (i) {
                  final item = result.items[i];
                  final palette = financialColors.portfolioPalette;
                  final dotColor = palette[i % palette.length];
                  final itemOutcome = item.calculation.outcome;
                  final itemColor = itemOutcome.color(context);
                  final itemSign = itemOutcome.explicitPositiveSign;
                  final pctFmt = AppFormat.percent(context.localeName);

                  return MergeSemantics(
                    child: Padding(
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
                          // Renk körü erişilebilirliği (CLAUDE.md): kar/zarar
                          // yalnız renkle değil, yön ikonuyla da gösterilir.
                          Icon(itemOutcome.icon, size: 16, color: itemColor),
                          const SizedBox(width: 4),
                          Text(
                            '$itemSign${pctFmt.format(item.calculation.profitLossPercent / 100)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: itemColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
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
