import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/theme/financial_colors.dart';
import 'package:saydin/core/utils/app_formatters.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';

class DcaChart extends StatefulWidget {
  final List<DcaChartPoint> chartData;
  final bool isProfit;

  const DcaChart({super.key, required this.chartData, required this.isProfit});

  @override
  State<DcaChart> createState() => _DcaChartState();
}

class _DcaChartState extends State<DcaChart> {
  bool _showData = false;

  @override
  Widget build(BuildContext context) {
    final chartData = widget.chartData;
    if (chartData.length < 2) return const SizedBox.shrink();

    final l10n = context.l10n;
    final locale = context.localeName;
    final tryFmt = AppFormat.tryCurrency(locale, decimalDigits: 0);
    final dateFmt = AppFormat.date(locale);
    final theme = Theme.of(context);
    final financialColors = context.financialColors;
    final valueColor = widget.isProfit
        ? financialColors.profit
        : financialColors.loss;
    final costColor = financialColors.chartCost;
    final origin = chartData.first.date;

    // fl_chart `FlSpot` double bekler; grafik display-only. Decimal precision
    // finansal aggregasyonda korunur.
    final costSpots = chartData
        .map(
          (p) => FlSpot(
            p.date.difference(origin).inDays.toDouble(),
            p.cumulativeCost.toDouble(),
          ),
        )
        .toList();
    final valueSpots = chartData
        .map(
          (p) => FlSpot(
            p.date.difference(origin).inDays.toDouble(),
            p.cumulativeValue.toDouble(),
          ),
        )
        .toList();

    final allY = [...costSpots, ...valueSpots].map((s) => s.y);
    final minY = allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.reduce((a, b) => a > b ? a : b);
    final yPad = (maxY - minY) * 0.12;
    final last = chartData.last;
    final summary = l10n.dcaChartSummary(
      dateFmt.format(chartData.first.date),
      dateFmt.format(last.date),
      tryFmt.format(last.cumulativeCost.toDouble()),
      tryFmt.format(last.cumulativeValue.toDouble()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            _LegendDot(color: costColor, label: l10n.dcaChartCost),
            _LegendDot(color: valueColor, label: l10n.dcaChartValue),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          container: true,
          image: true,
          label: summary,
          child: ExcludeSemantics(
            child: SizedBox(
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
                      getTooltipColor: (_) =>
                          theme.colorScheme.surfaceContainerHighest,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        if (touchedSpots.isEmpty) return [];
                        final date = origin.add(
                          Duration(days: touchedSpots.first.x.toInt()),
                        );
                        return touchedSpots.map((spot) {
                          final isValue = spot.barIndex == 1;
                          final seriesLabel = isValue
                              ? l10n.dcaChartValue
                              : l10n.dcaChartCost;
                          return LineTooltipItem(
                            '${dateFmt.format(date)}\n'
                            '$seriesLabel: ${tryFmt.format(spot.y)}',
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
                    LineChartBarData(
                      spots: costSpots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: costColor,
                      barWidth: 1.5,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
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
                            valueColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        TextButton.icon(
          key: const ValueKey('dca-chart-data-toggle'),
          onPressed: () => setState(() => _showData = !_showData),
          icon: Icon(_showData ? Icons.expand_less : Icons.table_rows),
          label: Text(_showData ? l10n.chartDataHide : l10n.chartDataShow),
        ),
        if (_showData)
          _DcaDataTable(
            chartData: chartData,
            dateFormatter: dateFmt,
            valueFormatter: tryFmt,
          ),
      ],
    );
  }
}

class _DcaDataTable extends StatelessWidget {
  final List<DcaChartPoint> chartData;
  final DateFormat dateFormatter;
  final NumberFormat valueFormatter;

  const _DcaDataTable({
    required this.chartData,
    required this.dateFormatter,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: Scrollbar(
        child: ListView.separated(
          key: const ValueKey('dca-chart-data-list'),
          primary: false,
          shrinkWrap: true,
          itemCount: chartData.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final point = chartData[index];
            final value = l10n.dcaChartDataPoint(
              dateFormatter.format(point.date),
              valueFormatter.format(point.cumulativeCost.toDouble()),
              valueFormatter.format(point.cumulativeValue.toDouble()),
            );
            return Semantics(
              container: true,
              label: value,
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Text(value),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
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
      ),
    );
  }
}
