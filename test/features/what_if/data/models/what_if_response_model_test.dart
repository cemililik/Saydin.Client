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

    // ── Enflasyon alanları ─────────────────────────────────────────────────

    test(
      'cumulativeInflationPercent ve realProfitLossPercent null gelince null döner',
      () {
        final model = WhatIfResponseModel.fromJson(_baseJson(priceHistory: []));

        expect(model.cumulativeInflationPercent, isNull);
        expect(model.realProfitLossPercent, isNull);
      },
    );

    test('enflasyon alanları dolu gelince doğru parse edilir', () {
      final json = {
        ..._baseJson(priceHistory: []),
        'cumulativeInflationPercent': 85.4,
        'realProfitLossPercent': -22.7,
      };

      final model = WhatIfResponseModel.fromJson(json);

      expect(model.cumulativeInflationPercent, closeTo(85.4, 0.001));
      expect(model.realProfitLossPercent, closeTo(-22.7, 0.001));
    });

    test('inflationDataAsOf null gelince null döner', () {
      final model = WhatIfResponseModel.fromJson(_baseJson(priceHistory: []));

      expect(model.inflationDataAsOf, isNull);
    });

    test('inflationDataAsOf dolu gelince DateTime parse edilir', () {
      final json = {
        ..._baseJson(priceHistory: []),
        'inflationDataAsOf': '2026-01-01',
      };

      final model = WhatIfResponseModel.fromJson(json);

      expect(model.inflationDataAsOf, DateTime(2026, 1, 1));
    });

    // ── Haftasonu / tarih düzeltmesi alanları ────────────────────────────

    test('actualBuyDate ve actualSellDate null gelince null döner', () {
      final model = WhatIfResponseModel.fromJson(_baseJson(priceHistory: []));

      expect(model.actualBuyDate, isNull);
      expect(model.actualSellDate, isNull);
    });

    test('actualBuyDate dolu gelince DateTime parse edilir', () {
      final json = {
        ..._baseJson(priceHistory: []),
        'actualBuyDate': '2020-01-03', // Cuma (Cumartesi seçilmişti)
      };

      final model = WhatIfResponseModel.fromJson(json);

      expect(model.actualBuyDate, DateTime(2020, 1, 3));
      expect(model.actualSellDate, isNull);
    });

    test('actualSellDate dolu gelince DateTime parse edilir', () {
      final json = {
        ..._baseJson(priceHistory: []),
        'actualSellDate': '2021-01-01',
      };

      final model = WhatIfResponseModel.fromJson(json);

      expect(model.actualSellDate, DateTime(2021, 1, 1));
    });

    test('tüm nullable alanlar aynı anda dolu parse edilebilir', () {
      final json = {
        ..._baseJson(priceHistory: []),
        'cumulativeInflationPercent': 120.5,
        'realProfitLossPercent': -15.3,
        'inflationDataAsOf': '2026-01-01',
        'actualBuyDate': '2020-01-03',
        'actualSellDate': '2021-01-01',
      };

      final model = WhatIfResponseModel.fromJson(json);

      expect(model.cumulativeInflationPercent, closeTo(120.5, 0.001));
      expect(model.realProfitLossPercent, closeTo(-15.3, 0.001));
      expect(model.inflationDataAsOf, DateTime(2026, 1, 1));
      expect(model.actualBuyDate, DateTime(2020, 1, 3));
      expect(model.actualSellDate, DateTime(2021, 1, 1));
    });
  });
}
