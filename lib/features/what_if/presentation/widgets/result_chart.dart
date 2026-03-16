import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/constants/app_colors.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

final _priceFmt = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 2,
);
final _dateFmt = DateFormat('dd.MM.yyyy', 'tr_TR');

class ResultChart extends StatefulWidget {
  final WhatIfResult result;

  const ResultChart({super.key, required this.result});

  @override
  State<ResultChart> createState() => _ResultChartState();
}

class _ResultChartState extends State<ResultChart> {
  bool _isRangeMode = false;
  int? _fromIdx;
  int? _toIdx;

  int? _closestIndex(LineTouchResponse? response) =>
      response?.lineBarSpots?.firstOrNull?.spotIndex;

  void _onTouch(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlLongPressStart) {
      final idx = _closestIndex(response);
      if (idx != null) {
        setState(() {
          _isRangeMode = true;
          _fromIdx = idx;
          _toIdx = idx;
        });
      }
    } else if (event is FlLongPressMoveUpdate) {
      final idx = _closestIndex(response);
      if (idx != null) setState(() => _toIdx = idx);
    } else if (event is FlTapUpEvent && _isRangeMode) {
      setState(() {
        _isRangeMode = false;
        _fromIdx = null;
        _toIdx = null;
      });
    }
  }

  @override
  void didUpdateWidget(ResultChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.priceHistory != widget.result.priceHistory) {
      _isRangeMode = false;
      _fromIdx = null;
      _toIdx = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.result.priceHistory;
    if (history.length < 2) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = widget.result.isProfit ? AppColors.profit : AppColors.loss;
    final origin = history.first.date;

    final spots = history
        .map(
          (p) => FlSpot(p.date.difference(origin).inDays.toDouble(), p.price),
        )
        .toList();

    final minY = spots.fold(spots.first.y, (m, s) => s.y < m ? s.y : m);
    final maxY = spots.fold(spots.first.y, (m, s) => s.y > m ? s.y : m);
    final yPad = (maxY - minY) * 0.12;

    // Aralık hesabı — küçük index her zaman "from"
    final hasRange =
        _isRangeMode &&
        _fromIdx != null &&
        _toIdx != null &&
        _fromIdx != _toIdx;

    final normFrom = hasRange
        ? (_fromIdx! < _toIdx! ? _fromIdx! : _toIdx!)
        : null;
    final normTo = hasRange
        ? (_fromIdx! < _toIdx! ? _toIdx! : _fromIdx!)
        : null;

    final vLineColor = theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final tooltipBg = theme.colorScheme.surfaceContainerHighest;
    final tooltipFg = theme.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 96,
          child: LineChart(
            LineChartData(
              minY: minY - yPad,
              maxY: maxY + yPad,
              clipData: const FlClipData.all(),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              rangeAnnotations: RangeAnnotations(
                verticalRangeAnnotations: [
                  if (hasRange)
                    VerticalRangeAnnotation(
                      x1: spots[normFrom!].x,
                      x2: spots[normTo!].x,
                      color: color.withValues(alpha: 0.12),
                    ),
                ],
              ),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  if (_fromIdx != null)
                    VerticalLine(
                      x: spots[_fromIdx!].x,
                      color: vLineColor,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  if (_toIdx != null && _toIdx != _fromIdx)
                    VerticalLine(
                      x: spots[_toIdx!].x,
                      color: vLineColor,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                ],
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: !_isRangeMode,
                touchCallback: _onTouch,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => tooltipBg,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                    final date = origin.add(Duration(days: s.x.toInt()));
                    return LineTooltipItem(
                      '${_dateFmt.format(date)}\n${_priceFmt.format(s.y)}',
                      TextStyle(color: tooltipFg, fontSize: 11, height: 1.6),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: color,
                  barWidth: 1.8,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.18),
                        color.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasRange) ...[
          const SizedBox(height: 8),
          _RangeInfoBar(from: history[normFrom!], to: history[normTo!]),
        ],
      ],
    );
  }
}

class _RangeInfoBar extends StatelessWidget {
  final ChartPoint from;
  final ChartPoint to;

  const _RangeInfoBar({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final delta = to.price - from.price;
    final pct = from.price == 0 ? 0.0 : delta / from.price * 100;
    final isUp = delta >= 0;
    final color = isUp ? AppColors.profit : AppColors.loss;
    final theme = Theme.of(context);

    final pctStr =
        '${isUp ? "+" : ""}${NumberFormat.decimalPercentPattern(locale: "tr_TR", decimalDigits: 2).format(pct / 100)}';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_dateFmt.format(from.date)} → ${_dateFmt.format(to.date)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            pctStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
