import 'package:flutter/material.dart';
import 'package:saydin/core/constants/app_branding.dart';
import 'package:saydin/core/constants/brand_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/theme/financial_outcome_style.dart';
import 'package:saydin/core/utils/app_formatters.dart';
import 'package:saydin/core/widgets/share_card_surface.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';

/// Karşılaştırma sonucunu sosyal medyaya paylaşmak için render edilen kart.
class ComparisonShareCardWidget extends StatelessWidget {
  final CompareResult result;
  final DateTime buyDate;
  final DateTime? sellDate;

  const ComparisonShareCardWidget({
    super.key,
    required this.result,
    required this.buyDate,
    this.sellDate,
  });

  static const _rankEmojis = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Locale'e duyarlı formatter'lar (F-06-01).
    final locale = context.localeName;
    final pctFmt = AppFormat.percent(locale);
    final dateFmt = AppFormat.date(locale);
    final effectiveSellDate =
        sellDate ?? result.results.firstOrNull?.calculation.effectiveSellDate;
    final sellLabel = dateFmt.format(effectiveSellDate ?? buyDate);

    return ShareCardSurface(
      children: [
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
                      l10n.shareCardComparisonTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: ShareCardColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ShareCardColors.brandSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ShareCardWidget.durationLabel(
                        l10n,
                        buyDate,
                        effectiveSellDate ?? buyDate,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: BrandColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${dateFmt.format(buyDate)}  →  $sellLabel',
                style: const TextStyle(
                  fontSize: 13,
                  color: ShareCardColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Ranked list
              ...result.results.take(5).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final pct = item.calculation.profitLossPercent;
                final outcome = item.calculation.outcome;
                final sign = outcome.explicitPositiveSign;
                final isWinner = item.rank == 1;
                final itemColor = outcome.shareColor;
                final emoji = i < _rankEmojis.length ? _rankEmojis[i] : '•';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isWinner
                        ? ShareCardColors.brandSurface
                        : ShareCardColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isWinner
                          ? ShareCardColors.brandBorder
                          : ShareCardColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.calculation.assetDisplayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isWinner
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: ShareCardColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '$sign${pctFmt.format(pct / 100)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: itemColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        // Footer
        Container(
          color: ShareCardColors.surfaceSubtle,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.shareCardComparisonFooter,
                style: const TextStyle(
                  fontSize: 12,
                  color: ShareCardColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                AppBranding.domain,
                style: TextStyle(
                  fontSize: 12,
                  color: BrandColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
