import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';

final _tryFmt = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 0,
);
final _dateFmt = DateFormat('dd.MM.yyyy', 'tr_TR');

class DcaChart extends StatelessWidget {
  final List<DcaChartPoint> chartData;
  final bool isProfit;

  const DcaChart({super.key, required this.chartData, required this.isProfit});

  @override
  Widget build(BuildContext context) {
    if (chartData.length < 2) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final valueColor = isProfit ? AppColors.profit : AppColors.loss;
    const costColor = Color(0xFF757575);
    final origin = chartData.first.date;

    final costSpots = chartData
        .map(
          (p) => FlSpot(
            p.date.difference(origin).inDays.toDouble(),
            p.cumulativeCost,
          ),
        )
        .toList();

    final valueSpots = chartData
        .map(
          (p) => FlSpot(
            p.date.difference(origin).inDays.toDouble(),
            p.cumulativeValue,
          ),
        )
        .toList();

    final allY = [...costSpots, ...valueSpots].map((s) => s.y);
    final minY = allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.reduce((a, b) => a > b ? a : b);
    final yPad = (maxY - minY) * 0.12;

    final tooltipBg = theme.colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lejant
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: costColor, label: l10n.dcaChartCost),
            const SizedBox(width: 16),
            _LegendDot(color: valueColor, label: l10n.dcaChartValue),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: minY - yPad,
              maxY: maxY + yPad,
              clipData: const FlClipData.all(),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => tooltipBg,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) {
                    if (touchedSpots.isEmpty) return [];
                    final date = origin.add(
                      Duration(days: touchedSpots.first.x.toInt()),
                    );
                    return touchedSpots.map((s) {
                      final isValue = s.barIndex == 1;
                      return LineTooltipItem(
                        isValue
                            ? '${_dateFmt.format(date)}\n${_tryFmt.format(s.y)}'
                            : _tryFmt.format(s.y),
                        TextStyle(
                          color: isValue ? valueColor : costColor,
                          fontSize: 11,
                          height: 1.6,
                          fontWeight: isValue ? FontWeight.bold : null,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // Toplam maliyet — gri kesikli çizgi
                LineChartBarData(
                  spots: costSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: costColor,
                  barWidth: 1.5,
                  dashArray: [6, 4],
                  dotData: const FlDotData(show: false),
                ),
                // Güncel değer — renkli dolgu
                LineChartBarData(
                  spots: valueSpots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: valueColor,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        valueColor.withValues(alpha: 0.18),
                        valueColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
