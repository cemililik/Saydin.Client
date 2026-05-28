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
    final rawHistory = json['priceHistory'];
    final priceHistory = rawHistory is List
        ? rawHistory.map((e) {
            if (e is! Map) {
              throw const FormatException('reverse what-if chart: map değil');
            }
            return ChartPoint(
              date: _parseDate(e['date'], 'priceHistory.date'),
              price: _requireNum(e['price'], 'priceHistory.price').toDouble(),
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
      buyPrice: _requireNum(json['buyPrice'], 'buyPrice').toDouble(),
      sellPrice: _requireNum(json['sellPrice'], 'sellPrice').toDouble(),
      requiredInvestmentTry: _requireNum(
        json['requiredInvestmentTry'],
        'requiredInvestmentTry',
      ).toDouble(),
      unitsAcquired: _requireNum(
        json['unitsAcquired'],
        'unitsAcquired',
      ).toDouble(),
      targetValueTry: _requireNum(
        json['targetValueTry'],
        'targetValueTry',
      ).toDouble(),
      profitLossTry: _requireNum(
        json['profitLossTry'],
        'profitLossTry',
      ).toDouble(),
      profitLossPercent: _requireNum(
        json['profitLossPercent'],
        'profitLossPercent',
      ).toDouble(),
      isProfit: json['isProfit'] is bool ? json['isProfit'] as bool : false,
      priceHistory: priceHistory,
      cumulativeInflationPercent: _optionalNum(
        json['cumulativeInflationPercent'],
      )?.toDouble(),
      realProfitLossPercent: _optionalNum(
        json['realProfitLossPercent'],
      )?.toDouble(),
      inflationDataAsOf: _optionalDate(json['inflationDataAsOf']),
      actualBuyDate: _optionalDate(json['actualBuyDate']),
      actualSellDate: _optionalDate(json['actualSellDate']),
    );
  }

  // ── Defensive parse yardımcıları ────────────────────────────────────────
  // Bkz. `dca_response_model.dart` — aynı mantık. Bir kontrat kırılması
  // tüm sayfayı çökertmek yerine `FormatException` ile `DioErrorMapper`
  // üzerinden `BadResponseError` olarak ele alınır.

  static num _requireNum(Object? value, String field) {
    if (value is num) return value;
    throw FormatException('reverse what-if: $field sayı değil ($value)');
  }

  static num? _optionalNum(Object? value) => value is num ? value : null;

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
