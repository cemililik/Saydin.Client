import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/what_if/data/models/asset_model.dart';

void main() {
  group('AssetModel.fromJson', () {
    test('tüm alanları doğru parse eder', () {
      final json = {
        'symbol': 'USDTRY',
        'displayName': 'Dolar/TL',
        'category': 'currency',
        'firstPriceDate': '2020-01-01',
        'lastPriceDate': '2024-12-31',
      };

      final model = AssetModel.fromJson(json);

      expect(model.symbol, 'USDTRY');
      expect(model.displayName, 'Dolar/TL');
      expect(model.category, 'currency');
      expect(model.firstDate, DateTime(2020, 1, 1));
      expect(model.lastDate, DateTime(2024, 12, 31));
    });

    test('null tarihler → firstDate ve lastDate null döner', () {
      final json = {
        'symbol': 'NEWASSET',
        'displayName': 'Yeni Varlık',
        'category': 'crypto',
        'firstPriceDate': null,
        'lastPriceDate': null,
      };

      final model = AssetModel.fromJson(json);

      expect(model.firstDate, isNull);
      expect(model.lastDate, isNull);
    });

    test('tarih alanları yoksa → firstDate ve lastDate null döner', () {
      final json = {
        'symbol': 'NEWASSET',
        'displayName': 'Yeni Varlık',
        'category': 'crypto',
      };

      final model = AssetModel.fromJson(json);

      expect(model.firstDate, isNull);
      expect(model.lastDate, isNull);
    });

    test(
      'kategori precious_metal → allowedAmountTypes try ve grams içerir',
      () {
        final json = {
          'symbol': 'XAUTRY',
          'displayName': 'Altın/TL',
          'category': 'precious_metal',
        };

        final model = AssetModel.fromJson(json);

        expect(model.allowedAmountTypes, containsAll(['try', 'grams']));
        expect(model.allowedAmountTypes, isNot(contains('units')));
      },
    );

    test('kategori currency → allowedAmountTypes try ve units içerir', () {
      final json = {
        'symbol': 'USDTRY',
        'displayName': 'Dolar/TL',
        'category': 'currency',
      };

      final model = AssetModel.fromJson(json);

      expect(model.allowedAmountTypes, containsAll(['try', 'units']));
      expect(model.allowedAmountTypes, isNot(contains('grams')));
    });

    test('zorunlu alan eksikse FormatException fırlatır', () {
      final json = {
        'symbol': 'USDTRY',
        // displayName eksik
        'category': 'currency',
      };

      expect(() => AssetModel.fromJson(json), throwsA(isA<FormatException>()));
    });
  });
}
