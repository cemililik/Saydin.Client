import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/scenarios/data/models/saved_scenario_model.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

void main() {
  Map<String, dynamic> baseJson({
    Object? id = 'abc-123',
    Object? buyDate = '2020-03-01',
    Object? amountType = 'try',
    Object? createdAt = '2026-01-01T12:00:00Z',
    String type = 'what_if',
  }) => {
    'id': id,
    'type': type,
    'assetSymbol': 'USDTRY',
    'assetDisplayName': 'Dolar/TL',
    'buyDate': buyDate,
    'sellDate': '2021-01-01',
    'amount': 10000,
    'amountType': amountType,
    'createdAt': createdAt,
  };

  group('SavedScenarioModel.fromJson (F-11-20 defansif parse)', () {
    test('geçerli json doğru entity üretir', () {
      final m = SavedScenarioModel.fromJson(baseJson());
      expect(m.id, 'abc-123');
      expect(m.assetSymbol, 'USDTRY');
      expect(m.buyDate, DateTime(2020, 3, 1));
      expect(m.sellDate, DateTime(2021, 1, 1));
      expect(m.amount, Decimal.fromInt(10000));
      expect(m.type, ScenarioType.whatIf);
    });

    test('bilinmeyen type → FormatException (whatIf fail-open yok)', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson(type: 'gelecekteki_tip')),
        throwsFormatException,
      );
    });

    test('id yanlış tipte (int) → FormatException (raw TypeError değil)', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson(id: 42)),
        throwsFormatException,
      );
    });

    test('amountType eksik/null → FormatException', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson(amountType: null)),
        throwsFormatException,
      );
    });

    test('bozuk buyDate ("2020") → FormatException (RangeError değil)', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson(buyDate: '2020')),
        throwsFormatException,
      );
    });

    test('bozuk buyDate ("x-y-z") → FormatException', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson(buyDate: 'x-y-z')),
        throwsFormatException,
      );
    });

    test(
      'aralık dışı tarih ("2020-13-45") silent rollover yerine FormatException',
      () {
        // DateTime(2020,13,45) sessizce 2021-02-14'e kayardı; round-trip
        // doğrulaması bunu yakalar.
        expect(
          () => SavedScenarioModel.fromJson(baseJson(buyDate: '2020-13-45')),
          throwsFormatException,
        );
      },
    );

    test('type yanlış tipte (int) → TypeError değil, FormatException', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson()..['type'] = 42),
        throwsFormatException,
      );
    });

    test('type eksik → FormatException', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson()..remove('type')),
        throwsFormatException,
      );
    });

    test('tüm canonical type değerleri geriye uyumlu parse edilir', () {
      expect(
        SavedScenarioModel.fromJson(baseJson(type: 'comparison')).type,
        ScenarioType.comparison,
      );
      expect(
        SavedScenarioModel.fromJson(baseJson(type: 'portfolio')).type,
        ScenarioType.portfolio,
      );
      expect(
        SavedScenarioModel.fromJson(baseJson(type: 'dca')).type,
        ScenarioType.dca,
      );
    });

    test('version alanı olmayan legacy extraData kabul edilir', () {
      final model = SavedScenarioModel.fromJson(
        baseJson()..['extraData'] = {'mode': 'reverse'},
      );

      expect(model.extraData, {'mode': 'reverse'});
    });

    test('future/bozuk extraData schemaVersion → FormatException', () {
      for (final version in <Object>[999, '2']) {
        expect(
          () => SavedScenarioModel.fromJson(
            baseJson()..['extraData'] = {'schemaVersion': version},
          ),
          throwsFormatException,
        );
      }
    });

    test('extraData map değilse → FormatException', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson()..['extraData'] = 'bozuk'),
        throwsFormatException,
      );
    });

    test(
      'createdAt boşluk-ayraçlı ISO ("2026-01-01 12:00:00") tolere edilir',
      () {
        // 'T' yerine boşluk kullanan backend'ler de kabul edilmeli (eski
        // DateTime.parse davranışı korunur; sessizce listeden düşmesin).
        final m = SavedScenarioModel.fromJson(
          baseJson(createdAt: '2026-01-01 12:00:00'),
        );
        expect(m.createdAt.year, 2026);
        expect(m.createdAt.month, 1);
        expect(m.createdAt.day, 1);
      },
    );

    test('createdAt T-ayraçlı ISO da tolere edilir', () {
      final m = SavedScenarioModel.fromJson(
        baseJson(createdAt: '2026-01-01T12:00:00Z'),
      );
      expect(m.createdAt.toUtc().year, 2026);
    });

    test('bozuk createdAt → FormatException', () {
      expect(
        () => SavedScenarioModel.fromJson(baseJson(createdAt: 'not-a-date')),
        throwsFormatException,
      );
    });
  });
}
