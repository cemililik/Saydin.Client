import 'package:flutter/material.dart';
import 'package:saydin/core/constants/app_branding.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/app_formatters.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';

/// Portföy sonucunu sosyal medyaya paylaşmak için render edilen kart.
class PortfolioShareCardWidget extends StatelessWidget {
  static const _maxVisibleItems = 6;

  final PortfolioResult result;
  final DateTime buyDate;
  final DateTime? sellDate;

  const PortfolioShareCardWidget({
    super.key,
    required this.result,
    required this.buyDate,
    this.sellDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Locale'e duyarlı formatter'lar (F-06-01).
    final locale = context.localeName;
    final tryFmt = AppFormat.tryCurrency(locale);
    final pctFmt = AppFormat.percent(locale);
    final dateFmt = AppFormat.date(locale);
    final color = result.isProfit ? AppColors.profit : AppColors.loss;
    final icon = result.isProfit ? Icons.trending_up : Icons.trending_down;
    final sign = result.totalProfitLossPercent >= 0 ? '+' : '';
    final effectiveSellDate = sellDate ?? result.effectiveSellDate ?? buyDate;
    final sellLabel = dateFmt.format(effectiveSellDate);

    final hasInflation = result.totalRealProfitLossPercent != null;
    final realPct = result.totalRealProfitLossPercent ?? 0;
    final realSign = realPct >= 0 ? '+' : '';
    final realColor = realPct >= 0 ? AppColors.profit : AppColors.loss;
    final visibleItems = result.items.take(_maxVisibleItems).toList();
    final remainingItemCount = result.items.length - visibleItems.length;

    return SizedBox(
      width: 540,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 6, color: AppColors.primary),

            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Center(
                child: Text(
                  AppBranding.wordmark,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),

            Container(height: 1, color: const Color(0xFFEEEEEE)),

            Padding(
              padding: const EdgeInsets.fromLTRB(32, 22, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık + süre chip
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.shareCardPortfolioTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ShareCardWidget.durationLabel(
                            l10n,
                            buyDate,
                            effectiveSellDate,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${dateFmt.format(buyDate)}  →  $sellLabel',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.shareCardAssetCount(result.items.length),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 12),

                  // Varlık listesi
                  ...visibleItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.item.assetDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF444444),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            tryFmt.format(
                              item.calculation.initialValueTry.toDouble(),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (remainingItemCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        l10n.shareCardMoreAssets(remainingItemCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Başlangıç → Son değer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDDE5FF)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.shareCardTotalInvestment,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tryFmt.format(
                                  result.totalInitialValueTry.toDouble(),
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.shareCardFinalValue,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tryFmt.format(
                                  result.totalFinalValueTry.toDouble(),
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Toplam getiri kutusu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          hasInflation
                              ? l10n.shareCardNominalTotalReturn
                              : l10n.shareCardTotalReturn,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(icon, color: color, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              '$sign${pctFmt.format(result.totalProfitLossPercent / 100)}',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: color,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sign${tryFmt.format(result.totalProfitLossTry.toDouble())} '
                          '${result.isProfit ? l10n.shareCardProfit : l10n.shareCardLoss}',
                          style: TextStyle(
                            fontSize: 15,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enflasyon bölümü
                  if (hasInflation) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDDDDD)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.shareCardCumulativeInflation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              Text(
                                '${(result.totalCumulativeInflationPercent ?? 0) >= 0 ? '+' : ''}'
                                '${pctFmt.format((result.totalCumulativeInflationPercent ?? 0) / 100)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFDDDDDD)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.shareCardRealReturn,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                '$realSign${pctFmt.format(realPct / 100)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: realColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Footer
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.shareCardPortfolioFooter,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    AppBranding.domain,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
