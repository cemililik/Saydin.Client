import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';

class ComparisonResultCard extends StatefulWidget {
  final CompareResultItem item;

  const ComparisonResultCard({super.key, required this.item});

  @override
  State<ComparisonResultCard> createState() => _ComparisonResultCardState();
}

class _ComparisonResultCardState extends State<ComparisonResultCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  CompareResultItem get item => widget.item;

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
    // Stagger: rank'e göre gecikme
    Future.delayed(Duration(milliseconds: (item.rank - 1) * 100), () {
      if (mounted) _controller.forward();
    });
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
  static final _pctFormatter = NumberFormat.decimalPercentPattern(
    locale: 'tr_TR',
    decimalDigits: 2,
  );
  static final _dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final calc = item.calculation;
    final color = calc.isProfit ? AppColors.profit : AppColors.loss;
    final icon = calc.isProfit ? Icons.trending_up : Icons.trending_down;
    final sellLabel = calc.sellDate != null
        ? _dateFormatter.format(calc.sellDate!)
        : l10n.today;

    final hasDateNote =
        calc.actualBuyDate != null || calc.actualSellDate != null;
    final realColor = (calc.realProfitLossPercent ?? 0) >= 0
        ? AppColors.profit
        : AppColors.loss;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: item.rank == 1 ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: item.rank == 1
                ? BorderSide(color: color, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ana satır: badge + isim/tarih + değerler ─────
                Row(
                  children: [
                    _RankBadge(rank: item.rank, color: color),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: color, size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  calc.assetDisplayName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_dateFormatter.format(calc.buyDate)} → $sellLabel',
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

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _tryFormatter.format(calc.finalValueTry),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${calc.profitLossPercent >= 0 ? '+' : ''}'
                          '${_pctFormatter.format(calc.profitLossPercent / 100)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (calc.realProfitLossPercent != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${l10n.realReturnPrefix}${calc.realProfitLossPercent! >= 0 ? '+' : ''}'
                            '${_pctFormatter.format(calc.realProfitLossPercent! / 100)}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: realColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // ── Tarih düzeltmesi notu (altta, tam genişlik) ──
                if (hasDateNote) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          context.l10n.dateAdjustedNote,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
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

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isFirst ? color : color.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            color: isFirst ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
