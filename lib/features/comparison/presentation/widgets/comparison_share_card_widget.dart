import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';

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

  static final _pctFormatter = NumberFormat.decimalPercentPattern(
    locale: 'tr_TR',
    decimalDigits: 2,
  );
  static final _dateFormatter = DateFormat('dd.MM.yyyy', 'tr_TR');

  static const _rankEmojis = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];

  String get _durationLabel {
    final end = sellDate ?? DateTime.now();
    final months = (end.year - buyDate.year) * 12 + end.month - buyDate.month;
    if (months < 1) return '${end.difference(buyDate).inDays} gün';
    if (months < 12) return '$months ay';
    final years = months ~/ 12;
    final rem = months % 12;
    return rem > 0 ? '$years yıl $rem ay' : '$years yıl';
  }

  @override
  Widget build(BuildContext context) {
    final sellLabel = sellDate != null
        ? _dateFormatter.format(sellDate!)
        : _dateFormatter.format(DateTime.now());

    return SizedBox(
      width: 540,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top accent
            Container(height: 6, color: AppColors.primary),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: const Center(
                child: Text(
                  'saydın',
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
                      const Expanded(
                        child: Text(
                          'Varlık Karşılaştırması',
                          style: TextStyle(
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
                          _durationLabel,
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
                    '${_dateFormatter.format(buyDate)}  →  $sellLabel',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 20),

                  // Ranked list
                  ...result.results.take(5).toList().asMap().entries.map((
                    entry,
                  ) {
                    final i = entry.key;
                    final item = entry.value;
                    final pct = item.calculation.profitLossPercent;
                    final sign = pct >= 0 ? '+' : '';
                    final isWinner = item.rank == 1;
                    final itemColor = pct >= 0
                        ? AppColors.profit
                        : AppColors.loss;
                    final emoji = i < _rankEmojis.length ? _rankEmojis[i] : '•';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? const Color(0xFFF0F4FF)
                            : const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isWinner
                              ? const Color(0xFFBBCCFF)
                              : const Color(0xFFEEEEEE),
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
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          Text(
                            '$sign${_pctFormatter.format(pct / 100)}',
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
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hangisi daha kazandırdı?',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'saydın.app',
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
