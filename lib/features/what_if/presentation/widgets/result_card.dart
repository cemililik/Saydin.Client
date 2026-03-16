import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

class ResultCard extends StatelessWidget {
  final WhatIfResult result;

  const ResultCard({super.key, required this.result});

  static final _tryFormatter =
      NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
  static final _pctFormatter =
      NumberFormat.decimalPercentPattern(locale: 'tr_TR', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final tryFormatter = _tryFormatter;
    final pctFormatter = _pctFormatter;

    final color =
        result.isProfit ? AppColors.profit : AppColors.loss;
    final icon =
        result.isProfit ? Icons.trending_up : Icons.trending_down;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  result.isProfit ? 'Kazanç' : 'Kayıp',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _Row('Başlangıç Değeri',
                tryFormatter.format(result.initialValueTry)),
            _Row('Bugünkü Değer',
                tryFormatter.format(result.finalValueTry),
                bold: true),
            _Row(
              result.isProfit ? 'Kar' : 'Zarar',
              tryFormatter.format(result.profitLossTry),
              valueColor: color,
            ),
            _Row(
              'Getiri',
              pctFormatter.format(result.profitLossPercent / 100),
              valueColor: color,
              bold: true,
            ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
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
