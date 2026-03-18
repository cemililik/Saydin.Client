import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';

/// Portföy sonucunu sosyal medyaya paylaşmak için render edilen kart.
class PortfolioShareCardWidget extends StatelessWidget {
  final PortfolioResult result;
  final DateTime buyDate;
  final DateTime? sellDate;

  const PortfolioShareCardWidget({
    super.key,
    required this.result,
    required this.buyDate,
    this.sellDate,
  });

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
    final color = result.isProfit ? AppColors.profit : AppColors.loss;
    final icon = result.isProfit ? Icons.trending_up : Icons.trending_down;
    final sign = result.totalProfitLossPercent >= 0 ? '+' : '';
    final sellLabel = sellDate != null
        ? _dateFormatter.format(sellDate!)
        : _dateFormatter.format(DateTime.now());

    final hasInflation = result.totalRealProfitLossPercent != null;
    final realPct = result.totalRealProfitLossPercent ?? 0;
    final realSign = realPct >= 0 ? '+' : '';
    final realColor = realPct >= 0 ? AppColors.profit : AppColors.loss;

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
                          'Portföy Getirisi',
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
                  const SizedBox(height: 6),
                  Text(
                    '${result.items.length} varlık',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 12),

                  // Varlık listesi
                  ...result.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.item.assetDisplayName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                            ),
                          ),
                          Text(
                            _tryFormatter.format(item.result.initialValueTry),
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
                                'Toplam Yatırım',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tryFormatter.format(
                                  result.totalInitialValueTry,
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
                                'Son Değer',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tryFormatter.format(result.totalFinalValueTry),
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
                          hasInflation ? 'Nominal Getiri' : 'Toplam Getiri',
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
                              '$sign${_pctFormatter.format(result.totalProfitLossPercent / 100)}',
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
                          '$sign${_tryFormatter.format(result.totalProfitLossTry)} '
                          '${result.isProfit ? 'kazanç' : 'zarar'}',
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
                              const Text(
                                'Birikimli Enflasyon',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              Text(
                                '${(result.totalCumulativeInflationPercent ?? 0) >= 0 ? '+' : ''}'
                                '${_pctFormatter.format((result.totalCumulativeInflationPercent ?? 0) / 100)}',
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
                              const Text(
                                'Reel Getiri',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                              Text(
                                '$realSign${_pctFormatter.format(realPct / 100)}',
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
                    'Portföyüm ne kazandırdı?',
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
