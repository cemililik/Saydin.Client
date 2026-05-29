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

    test('bilinmeyen type → whatIf default (sessiz veri kaybı yok)', () {
      final m = SavedScenarioModel.fromJson(baseJson(type: 'gelecekteki_tip'));
      expect(m.type, ScenarioType.whatIf);
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

    test('type yanlış tipte (int) → TypeError değil, whatIf default', () {
      final m = SavedScenarioModel.fromJson(baseJson()..['type'] = 42);
      expect(m.type, ScenarioType.whatIf);
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
