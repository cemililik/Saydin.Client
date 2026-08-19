import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/theme/financial_outcome_style.dart';
import 'package:saydin/core/utils/financial_outcome.dart';
import 'package:saydin/core/utils/app_formatters.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

class ResultChart extends StatefulWidget {
  final List<ChartPoint> priceHistory;
  final FinancialOutcome outcome;

  const ResultChart({
    super.key,
    required this.priceHistory,
    required this.outcome,
  });

  /// WhatIfResult'tan kolayca oluşturmak için factory-benzeri constructor.
  factory ResultChart.fromResult(WhatIfResult result, {Key? key}) =>
      ResultChart(
        key: key,
        priceHistory: result.priceHistory,
        outcome: result.outcome,
      );

  @override
  State<ResultChart> createState() => _ResultChartState();
}

class _ResultChartState extends State<ResultChart> {
  bool _isRangeMode = false;
  bool _showData = false;
  int? _fromIdx;
  int? _toIdx;

  // Locale'e duyarlı formatter'lar (F-06-01) — State.context ile çağrı anında.
  NumberFormat get _priceFmt => AppFormat.tryCurrency(context.localeName);
  DateFormat get _dateFmt => AppFormat.date(context.localeName);

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
    if (oldWidget.priceHistory != widget.priceHistory) {
      _isRangeMode = false;
      _fromIdx = null;
      _toIdx = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.priceHistory;
    if (history.length < 2) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = widget.outcome.color(context);
    final origin = history.first.date;
    final first = history.first;
    final last = history.last;
    final l10n = context.l10n;
    final summary = l10n.priceChartSummary(
      _dateFmt.format(first.date),
      _priceFmt.format(first.price.toDouble()),
      _dateFmt.format(last.date),
      _priceFmt.format(last.price.toDouble()),
      FinancialOutcome.fromAmount(last.price - first.price).title(l10n),
    );

    final spots = history
        .map(
          (p) => FlSpot(
            p.date.difference(origin).inDays.toDouble(),
            // fl_chart `FlSpot` double bekler; precision sadece grafik
            // tooltip'i için yeterli, finansal toplama bu noktadan
            // önce Decimal'da yapılmış.
            p.price.toDouble(),
          ),
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
        Semantics(
          container: true,
          image: true,
          label: summary,
          child: ExcludeSemantics(
            child: SizedBox(
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
                          TextStyle(
                            color: tooltipFg,
                            fontSize: 11,
                            height: 1.6,
                          ),
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
          ),
        ),
        if (hasRange) ...[
          const SizedBox(height: 8),
          _RangeInfoBar(from: history[normFrom!], to: history[normTo!]),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('price-chart-data-toggle'),
            onPressed: () => setState(() => _showData = !_showData),
            icon: Icon(_showData ? Icons.expand_less : Icons.table_rows),
            label: Text(_showData ? l10n.chartDataHide : l10n.chartDataShow),
          ),
        ),
        if (_showData)
          _PriceDataTable(
            history: history,
            dateFormatter: _dateFmt,
            priceFormatter: _priceFmt,
          ),
      ],
    );
  }
}

class _PriceDataTable extends StatelessWidget {
  final List<ChartPoint> history;
  final DateFormat dateFormatter;
  final NumberFormat priceFormatter;

  const _PriceDataTable({
    required this.history,
    required this.dateFormatter,
    required this.priceFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: Scrollbar(
        child: ListView.separated(
          key: const ValueKey('price-chart-data-list'),
          primary: false,
          shrinkWrap: true,
          itemCount: history.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final point = history[index];
            final value = l10n.chartDataPoint(
              dateFormatter.format(point.date),
              priceFormatter.format(point.price.toDouble()),
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

class _RangeInfoBar extends StatelessWidget {
  final ChartPoint from;
  final ChartPoint to;

  const _RangeInfoBar({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    // RangeInfoBar grafik tooltip — display-only. Decimal aritmetiği
    // burada precision farkı yaratmaz, double'a indirip aynı formülle
    // çalışmak okunabilirliği koruyor.
    final fromPrice = from.price.toDouble();
    final toPrice = to.price.toDouble();
    final delta = toPrice - fromPrice;
    final pct = fromPrice == 0 ? 0.0 : delta / fromPrice * 100;
    final outcome = FinancialOutcome.fromPercent(delta);
    final color = outcome.color(context);
    final theme = Theme.of(context);
    final locale = context.localeName;
    final dateFmt = AppFormat.date(locale);

    final pctStr =
        '${outcome.explicitPositiveSign}${AppFormat.percent(locale).format(pct / 100)}';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(outcome.icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${dateFmt.format(from.date)} → ${dateFmt.format(to.date)}',
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
