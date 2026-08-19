import 'package:saydin/core/error/response_body_validator.dart';
import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/core/utils/profit_direction_validator.dart';
import '../../domain/entities/dca_result.dart';

class DcaResponseModel extends DcaResult {
  const DcaResponseModel({
    required super.assetSymbol,
    required super.assetDisplayName,
    required super.startDate,
    required super.endDate,
    required super.period,
    required super.periodicAmount,
    required super.totalPurchases,
    required super.totalInvestedTry,
    required super.currentValueTry,
    required super.profitLossTry,
    required super.profitLossPercent,
    required super.isProfit,
    required super.averageCostPerUnit,
    required super.totalUnitsAcquired,
    required super.currentUnitPrice,
    super.cumulativeInflationPercent,
    super.realProfitLossPercent,
    super.inflationDataAsOf,
    super.calculatedAt,
    super.purchases,
    super.chartData,
  });

  factory DcaResponseModel.fromJson(Map<String, dynamic> json) {
    final profitLossTry = MoneyParser.requireDecimal(
      json['profitLossTry'],
      'profitLossTry',
    );
    final isProfit = ProfitDirectionValidator.derive(
      rawIsProfit: json['isProfit'],
      profitLossTry: profitLossTry,
      context: 'dca response',
    );
    final rawPurchases = json['purchases'];
    final purchases = rawPurchases is List<dynamic>
        ? rawPurchases.map((e) {
            if (e is! Map<Object?, Object?>) {
              throw const FormatException('dca purchase: map değil');
            }
            return DcaPurchase(
              date: _parseDate(e['date'], 'purchase.date'),
              price: MoneyParser.requireDecimal(e['price'], 'purchase.price'),
              unitsAcquired: MoneyParser.requireDecimal(
                e['unitsAcquired'],
                'purchase.unitsAcquired',
              ),
              cumulativeUnits: MoneyParser.requireDecimal(
                e['cumulativeUnits'],
                'purchase.cumulativeUnits',
              ),
              cumulativeCostTry: MoneyParser.requireDecimal(
                e['cumulativeCostTry'],
                'purchase.cumulativeCostTry',
              ),
              cumulativeValueTry: MoneyParser.requireDecimal(
                e['cumulativeValueTry'],
                'purchase.cumulativeValueTry',
              ),
            );
          }).toList()
        : <DcaPurchase>[];

    final rawChart = json['chartData'];
    final chartData = rawChart is List<dynamic>
        ? rawChart.map((e) {
            if (e is! Map<Object?, Object?>) {
              throw const FormatException('dca chart point: map değil');
            }
            return DcaChartPoint(
              date: _parseDate(e['date'], 'chart.date'),
              cumulativeCost: MoneyParser.requireDecimal(
                e['cumulativeCost'],
                'chart.cumulativeCost',
              ),
              cumulativeValue: MoneyParser.requireDecimal(
                e['cumulativeValue'],
                'chart.cumulativeValue',
              ),
            );
          }).toList()
        : <DcaChartPoint>[];

    return DcaResponseModel(
      assetSymbol: _requireString(json['assetSymbol'], 'assetSymbol'),
      assetDisplayName: _requireString(
        json['assetDisplayName'],
        'assetDisplayName',
      ),
      startDate: _parseDate(json['startDate'], 'startDate'),
      endDate: _parseDate(json['endDate'], 'endDate'),
      period: _requireString(json['period'], 'period'),
      periodicAmount: MoneyParser.requireDecimal(
        json['periodicAmount'],
        'periodicAmount',
      ),
      totalPurchases: _requireNum(
        json['totalPurchases'],
        'totalPurchases',
      ).toInt(),
      totalInvestedTry: MoneyParser.requireDecimal(
        json['totalInvestedTry'],
        'totalInvestedTry',
      ),
      currentValueTry: MoneyParser.requireDecimal(
        json['currentValueTry'],
        'currentValueTry',
      ),
      profitLossTry: profitLossTry,
      profitLossPercent: ResponseBodyValidator.requireFiniteDouble(
        json['profitLossPercent'],
        'profitLossPercent',
      ),
      isProfit: isProfit,
      averageCostPerUnit: MoneyParser.requireDecimal(
        json['averageCostPerUnit'],
        'averageCostPerUnit',
      ),
      totalUnitsAcquired: MoneyParser.requireDecimal(
        json['totalUnitsAcquired'],
        'totalUnitsAcquired',
      ),
      currentUnitPrice: MoneyParser.requireDecimal(
        json['currentUnitPrice'],
        'currentUnitPrice',
      ),
      cumulativeInflationPercent: ResponseBodyValidator.optionalFiniteDouble(
        json['cumulativeInflationPercent'],
        'cumulativeInflationPercent',
      ),
      realProfitLossPercent: ResponseBodyValidator.optionalFiniteDouble(
        json['realProfitLossPercent'],
        'realProfitLossPercent',
      ),
      inflationDataAsOf: _optionalDate(json['inflationDataAsOf']),
      purchases: purchases,
      chartData: chartData,
    );
  }

  // ── Defensive parse yardımcıları ────────────────────────────────────────
  // Backend kontratı değişirse (örn `totalPurchases` string'e döner)
  // `as int` cast'i tüm sayfayı çökertirdi. Bunun yerine FormatException
  // fırlatıp DioErrorMapper üzerinden tek bir BadResponseError'a çevrilir.

  static num _requireNum(Object? value, String field) {
    if (value is num) return value;
    throw FormatException('dca response: $field sayı değil ($value)');
  }

  static String _requireString(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('dca response: $field string değil ($value)');
  }

  static DateTime _parseDate(Object? value, String field) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('dca response: $field tarih değil ($value)');
  }

  static DateTime? _optionalDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
