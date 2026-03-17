import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

/// Sosyal medyada paylaşılmak üzere render edilecek kart.
/// Theme bağımsız: her zaman açık zemin, sabit renkler.
class ShareCardWidget extends StatelessWidget {
  final WhatIfResult result;

  const ShareCardWidget({super.key, required this.result});

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
    final color = result.isProfit ? AppColors.profit : AppColors.loss;
    final icon = result.isProfit ? Icons.trending_up : Icons.trending_down;
    final sign = result.profitLossPercent >= 0 ? '+' : '';
    final sellLabel = result.sellDate != null
        ? _dateFormatter.format(result.sellDate!)
        : _dateFormatter.format(DateTime.now());

    return SizedBox(
      width: 540,
      height: 540,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Üst aksan çizgisi ──────────────────────────────────────
            Container(height: 5, color: AppColors.primary),

            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'saydın',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '.app',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: const Color(0xFFEEEEEE)),

            // ── İçerik ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Varlık adı
                    Text(
                      result.assetDisplayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tarih aralığı
                    Text(
                      '${_dateFormatter.format(result.buyDate)}  →  $sellLabel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Yatırım → Son Değer
                    Row(
                      children: [
                        _ValueBox(
                          label: 'Yatırım',
                          value: _tryFormatter.format(result.initialValueTry),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.grey.shade400,
                            size: 22,
                          ),
                        ),
                        _ValueBox(
                          label: 'Son Değer',
                          value: _tryFormatter.format(result.finalValueTry),
                          bold: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Büyük yüzde
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(icon, color: color, size: 38),
                        const SizedBox(width: 8),
                        Text(
                          '$sign${_pctFormatter.format(result.profitLossPercent / 100)}',
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.bold,
                            color: color,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // TL tutarı
                    Text(
                      '$sign${_tryFormatter.format(result.profitLossTry)} '
                      '${result.isProfit ? 'kazanç' : 'zarar'}',
                      style: TextStyle(fontSize: 17, color: color),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────
            Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              child: Text(
                'Ya alsaydın?  ·  saydın.app',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ValueBox({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
