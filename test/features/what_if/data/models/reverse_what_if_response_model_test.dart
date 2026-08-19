import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/data/models/reverse_what_if_response_model.dart';

void main() {
  Map<String, dynamic> json() => {
    'assetSymbol': 'USDTRY',
    'assetDisplayName': 'Dolar/TL',
    'buyDate': '2020-01-01',
    'sellDate': '2021-01-01',
    'buyPrice': '5',
    'sellPrice': '10',
    'requiredInvestmentTry': '100',
    'unitsAcquired': '20',
    'targetValueTry': '200',
    'profitLossTry': '100',
    'profitLossPercent': 100,
  };

  test('eksik isProfit finansal işaretten türetilir', () {
    expect(ReverseWhatIfResponseModel.fromJson(json()).isProfit, isTrue);
  });

  test('yanlış tipte isProfit kontrat ihlalidir', () {
    expect(
      () => ReverseWhatIfResponseModel.fromJson({...json(), 'isProfit': 'yes'}),
      throwsFormatException,
    );
  });

  test('API yönü Decimal kâr/zarar işaretiyle çelişemez', () {
    expect(
      () => ReverseWhatIfResponseModel.fromJson({...json(), 'isProfit': false}),
      throwsFormatException,
    );
  });

  test('zorunlu ve opsiyonel yüzde alanları non-finite olamaz', () {
    for (final field in [
      'profitLossPercent',
      'cumulativeInflationPercent',
      'realProfitLossPercent',
    ]) {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => ReverseWhatIfResponseModel.fromJson({...json(), field: value}),
          throwsFormatException,
          reason: '$field=$value reddedilmeli',
        );
      }
    }
  });

  test('sıfır ve çok büyük finite yüzde değerleri geçerlidir', () {
    final model = ReverseWhatIfResponseModel.fromJson({
      ...json(),
      'profitLossPercent': 0.0,
      'cumulativeInflationPercent': double.maxFinite,
      'realProfitLossPercent': -double.maxFinite,
    });

    expect(model.profitLossPercent, 0.0);
    expect(model.cumulativeInflationPercent, double.maxFinite);
    expect(model.realProfitLossPercent, -double.maxFinite);
  });
}
