import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/data/models/what_if_response_model.dart';

Map<String, dynamic> _baseJson({
  List<dynamic>? priceHistory,
  Object? sellDate = '2021-01-01',
}) => {
  'assetSymbol': 'USDTRY',
  'assetDisplayName': 'Dolar/TL',
  'buyDate': '2020-01-01',
  'sellDate': sellDate,
  'buyPrice': 5.95,
  'sellPrice': 8.50,
  'unitsAcquired': 1680.672269,
  'initialValueTry': 10000.0,
  'finalValueTry': 14285.71,
  'profitLossTry': 4285.71,
  'profitLossPercent': 42.86,
  'isProfit': true,
  if (priceHistory != null) 'priceHistory': priceHistory,
};

void main() {
  group('WhatIfResponseModel.fromJson', () {
    test('tüm sayısal ve boolean alanları doğru parse eder', () {
      final model = WhatIfResponseModel.fromJson(_baseJson(priceHistory: []));

      expect(model.assetSymbol, 'USDTRY');
      expect(model.assetDisplayName, 'Dolar/TL');
      expect(model.buyDate, DateTime(2020, 1, 1));
      expect(model.sellDate, DateTime(2021, 1, 1));
      expect(model.buyPrice, 5.95);
      expect(model.sellPrice, 8.50);
      expect(model.initialValueTry, 10000.0);
      expect(model.finalValueTry, 14285.71);
      expect(model.profitLossTry, 4285.71);
      expect(model.profitLossPercent, 42.86);
      expect(model.isProfit, true);
    });

    test('sellDate null olduğunda null döner', () {
      final model = WhatIfResponseModel.fromJson(
        _baseJson(priceHistory: [], sellDate: null),
      );

      expect(model.sellDate, isNull);
    });

    test('priceHistory dizisi doğru parse edilir', () {
      final json = _baseJson(
        priceHistory: [
          {'date': '2020-01-01', 'price': 5.95},
          {'date': '2020-06-01', 'price': 6.80},
          {'date': '2021-01-01', 'price': 8.50},
        ],
      );

      final model = WhatIfResponseModel.fromJson(json);

      expect(model.priceHistory, hasLength(3));
      expect(model.priceHistory[0].price, 5.95);
      expect(model.priceHistory[0].date, DateTime(2020, 1, 1));
      expect(model.priceHistory[2].price, 8.50);
    });

    test('priceHistory alanı yoksa boş liste döner', () {
      final json = _baseJson(); // priceHistory anahtarı yok

      final model = WhatIfResponseModel.fromJson(json);

      expect(model.priceHistory, isEmpty);
    });

    test('priceHistory boş dizi → boş liste döner', () {
      final model = WhatIfResponseModel.fromJson(_baseJson(priceHistory: []));

      expect(model.priceHistory, isEmpty);
    });
  });
}
