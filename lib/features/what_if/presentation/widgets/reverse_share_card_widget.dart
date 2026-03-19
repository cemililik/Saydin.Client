import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';

/// Ters senaryo için sosyal medya paylaşım kartı.
/// Theme bağımsız: her zaman açık zemin, sabit renkler.
class ReverseShareCardWidget extends StatelessWidget {
  final ReverseWhatIfResult result;

  const ReverseShareCardWidget({super.key, required this.result});

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
    final nominalColor = result.isProfit ? AppColors.profit : AppColors.loss;
    final nominalIcon = result.isProfit
        ? Icons.trending_up
        : Icons.trending_down;
    final nominalSign = result.profitLossPercent >= 0 ? '+' : '';
    final sellLabel = result.sellDate != null
        ? _dateFormatter.format(result.sellDate!)
        : _dateFormatter.format(DateTime.now());

    final hasInflation =
        result.cumulativeInflationPercent != null &&
        result.realProfitLossPercent != null;

    return SizedBox(
      width: 540,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Üst aksan çizgisi ──────────────────────────────────────────
            Container(height: 6, color: AppColors.primary),

            // ── Header ─────────────────────────────────────────────────────
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

            // ── İçerik ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Varlık adı + süre chip
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          result.assetDisplayName,
                          style: const TextStyle(
                            fontSize: 24,
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
                            result.buyDate,
                            result.sellDate,
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
                    '${_dateFormatter.format(result.buyDate)}  →  $sellLabel',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 20),

                  // Gereken Yatırım → Hedef Değer kutusu
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
                                l10n.shareCardRequiredInvestment,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tryFormatter.format(
                                  result.requiredInvestmentTry,
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
                                l10n.shareCardTargetValue,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tryFormatter.format(result.targetValueTry),
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

                  // Nominal getiri kutusu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: nominalColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: nominalColor.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasInflation
                              ? l10n.shareCardNominalReturn
                              : l10n.shareCardReturn,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(nominalIcon, color: nominalColor, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              '$nominalSign${_pctFormatter.format(result.profitLossPercent / 100)}',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: nominalColor,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$nominalSign${_tryFormatter.format(result.profitLossTry)} '
                          '${result.isProfit ? l10n.shareCardProfit : l10n.shareCardLoss}',
                          style: TextStyle(
                            fontSize: 15,
                            color: nominalColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Enflasyon bölümü ───────────────────────────────────
                  if (hasInflation) ...[
                    const SizedBox(height: 12),
                    _InflationSection(result: result),
                  ],
                ],
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.shareCardReverseFooter,
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

// ── Enflasyon alt bölümü ──────────────────────────────────────────────────────

class _InflationSection extends StatelessWidget {
  final ReverseWhatIfResult result;

  const _InflationSection({required this.result});

  static final _pctFormatter = NumberFormat.decimalPercentPattern(
    locale: 'tr_TR',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final inflSign = (result.cumulativeInflationPercent ?? 0) >= 0 ? '+' : '';
    final realPct = result.realProfitLossPercent!;
    final realSign = realPct >= 0 ? '+' : '';
    final realColor = realPct >= 0 ? AppColors.profit : AppColors.loss;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_outlined,
                size: 14,
                color: Color(0xFF757575),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.shareCardInflationTitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.shareCardCumulativeInflation,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
              Text(
                '$inflSign${_pctFormatter.format(result.cumulativeInflationPercent! / 100)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
    );
  }
}
