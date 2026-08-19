import 'package:saydin/core/error/response_body_validator.dart';
import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/core/utils/profit_direction_validator.dart';
import '../../domain/entities/reverse_what_if_result.dart';
import '../../domain/entities/what_if_result.dart';

class ReverseWhatIfResponseModel extends ReverseWhatIfResult {
  const ReverseWhatIfResponseModel({
    required super.assetSymbol,
    required super.assetDisplayName,
    required super.buyDate,
    super.sellDate,
    required super.buyPrice,
    required super.sellPrice,
    required super.requiredInvestmentTry,
    required super.unitsAcquired,
    required super.targetValueTry,
    required super.profitLossTry,
    required super.profitLossPercent,
    required super.isProfit,
    super.priceHistory,
    super.cumulativeInflationPercent,
    super.realProfitLossPercent,
    super.inflationDataAsOf,
    super.actualBuyDate,
    super.actualSellDate,
  });

  factory ReverseWhatIfResponseModel.fromJson(Map<String, dynamic> json) {
    final profitLossTry = MoneyParser.requireDecimal(
      json['profitLossTry'],
      'profitLossTry',
    );
    final isProfit = ProfitDirectionValidator.derive(
      rawIsProfit: json['isProfit'],
      profitLossTry: profitLossTry,
      context: 'reverse what-if response',
    );
    final rawHistory = json['priceHistory'];
    final priceHistory = rawHistory is List<dynamic>
        ? rawHistory.map((e) {
            if (e is! Map<Object?, Object?>) {
              throw const FormatException('reverse what-if chart: map değil');
            }
            return ChartPoint(
              date: _parseDate(e['date'], 'priceHistory.date'),
              price: MoneyParser.requireDecimal(
                e['price'],
                'priceHistory.price',
              ),
            );
          }).toList()
        : <ChartPoint>[];

    return ReverseWhatIfResponseModel(
      assetSymbol: _requireString(json['assetSymbol'], 'assetSymbol'),
      assetDisplayName: _requireString(
        json['assetDisplayName'],
        'assetDisplayName',
      ),
      buyDate: _parseDate(json['buyDate'], 'buyDate'),
      sellDate: _optionalDate(json['sellDate']),
      buyPrice: MoneyParser.requireDecimal(json['buyPrice'], 'buyPrice'),
      sellPrice: MoneyParser.requireDecimal(json['sellPrice'], 'sellPrice'),
      requiredInvestmentTry: MoneyParser.requireDecimal(
        json['requiredInvestmentTry'],
        'requiredInvestmentTry',
      ),
      unitsAcquired: MoneyParser.requireDecimal(
        json['unitsAcquired'],
        'unitsAcquired',
      ),
      targetValueTry: MoneyParser.requireDecimal(
        json['targetValueTry'],
        'targetValueTry',
      ),
      profitLossTry: profitLossTry,
      profitLossPercent: ResponseBodyValidator.requireFiniteDouble(
        json['profitLossPercent'],
        'profitLossPercent',
      ),
      isProfit: isProfit,
      priceHistory: priceHistory,
      cumulativeInflationPercent: ResponseBodyValidator.optionalFiniteDouble(
        json['cumulativeInflationPercent'],
        'cumulativeInflationPercent',
      ),
      realProfitLossPercent: ResponseBodyValidator.optionalFiniteDouble(
        json['realProfitLossPercent'],
        'realProfitLossPercent',
      ),
      inflationDataAsOf: _optionalDate(json['inflationDataAsOf']),
      actualBuyDate: _optionalDate(json['actualBuyDate']),
      actualSellDate: _optionalDate(json['actualSellDate']),
    );
  }

  // ── Defensive parse yardımcıları ────────────────────────────────────────

  static String _requireString(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('reverse what-if: $field string değil ($value)');
  }

  static DateTime _parseDate(Object? value, String field) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('reverse what-if: $field tarih değil ($value)');
  }

  static DateTime? _optionalDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
