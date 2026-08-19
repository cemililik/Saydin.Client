import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/utils/scenario_replay_parser.dart';

void main() {
  test('schema version legacy/current kabul, future/bozuk reddedilir', () {
    expect(ScenarioReplayParser.hasSupportedSchema(null), isTrue);
    expect(
      ScenarioReplayParser.hasSupportedSchema({'schemaVersion': 1}),
      isTrue,
    );
    expect(
      ScenarioReplayParser.hasSupportedSchema({
        'schemaVersion': ScenarioReplayParser.currentSchemaVersion,
      }),
      isTrue,
    );
    expect(
      ScenarioReplayParser.hasSupportedSchema({'schemaVersion': 999}),
      isFalse,
    );
    expect(
      ScenarioReplayParser.hasSupportedSchema({'schemaVersion': '2'}),
      isFalse,
    );
  });

  test('comparison replay 2-5 unique symbol invariantını uygular', () {
    expect(ScenarioReplayParser.comparisonSymbols('A,B'), ['A', 'B']);
    expect(ScenarioReplayParser.comparisonSymbols('A,A'), isEmpty);
    expect(ScenarioReplayParser.comparisonSymbols('A,A,B'), isEmpty);
    expect(ScenarioReplayParser.comparisonSymbols('A'), isEmpty);
    expect(ScenarioReplayParser.comparisonSymbols('A,B,C,D,E,F'), isEmpty);
  });

  test('DCA period legacy migrate edilir, explicit v2 bozukluk reddedilir', () {
    expect(ScenarioReplayParser.dcaPeriod({'period': 'weekly'}), 'weekly');
    expect(ScenarioReplayParser.dcaPeriod({'period': 'daily'}), 'monthly');
    expect(ScenarioReplayParser.dcaPeriod(null), 'monthly');
    expect(
      ScenarioReplayParser.dcaPeriod({
        'schemaVersion': ScenarioReplayParser.currentSchemaVersion,
        'period': 'daily',
      }),
      isNull,
    );
  });

  test('What-If current-schema explicit bilinmeyen mode reddedilir', () {
    expect(
      ScenarioReplayParser.hasValidWhatIfMode({
        'schemaVersion': ScenarioReplayParser.currentSchemaVersion,
      }),
      isTrue,
    );
    expect(
      ScenarioReplayParser.hasValidWhatIfMode({
        'schemaVersion': ScenarioReplayParser.currentSchemaVersion,
        'mode': 'reverse',
      }),
      isTrue,
    );
    expect(
      ScenarioReplayParser.hasValidWhatIfMode({
        'schemaVersion': ScenarioReplayParser.currentSchemaVersion,
        'mode': 'future-mode',
      }),
      isFalse,
    );
    expect(
      ScenarioReplayParser.hasValidWhatIfMode({
        'schemaVersion': ScenarioReplayParser.currentSchemaVersion,
        'mode': 7,
      }),
      isFalse,
    );
  });

  test(
    'portfolio eski num ve yeni canonical string tutarlarını Decimal yapar',
    () {
      var id = 0;
      final items = ScenarioReplayParser.portfolioItems([
        {
          'assetSymbol': 'A',
          'assetDisplayName': 'Asset A',
          'amount': 0.1,
          'amountType': 'units',
        },
        {
          'assetSymbol': 'B',
          'assetDisplayName': 'Asset B',
          'amount': '0.00000001',
          'amountType': 'units',
        },
      ], nextId: () => 'id-${id++}');

      expect(items.map((item) => item.amount), [
        Decimal.parse('0.1'),
        Decimal.parse('0.00000001'),
      ]);
    },
  );

  test('portfolio bozuk/limit dışı replay kalemlerini reddeder', () {
    final items = ScenarioReplayParser.portfolioItems([
      {
        'assetSymbol': 'A',
        'assetDisplayName': 'A',
        'amount': '1.001',
        'amountType': 'try',
      },
      {'assetSymbol': 'B', 'amount': '1', 'amountType': 'try'},
    ], nextId: () => 'id');

    expect(items, isEmpty);
  });

  test('portfolio replay duplicate sembolü kısmi sonuç üretmeden reddeder', () {
    final items = ScenarioReplayParser.portfolioItems([
      {
        'assetSymbol': 'A',
        'assetDisplayName': 'A',
        'amount': '1',
        'amountType': 'try',
      },
      {
        'assetSymbol': 'A',
        'assetDisplayName': 'A duplicate',
        'amount': '2',
        'amountType': 'try',
      },
    ], nextId: () => 'id');

    expect(items, isEmpty);
  });

  test(
    'DCA periodicAmount legacy bozukta fallback, explicit v2 bozukta null',
    () {
      expect(
        ScenarioReplayParser.dcaPeriodicAmount(
          {'periodicAmount': '1000.01'},
          Decimal.one,
          amountType: 'try',
        ),
        Decimal.parse('1000.01'),
      );
      expect(
        ScenarioReplayParser.dcaPeriodicAmount(
          {'periodicAmount': 'bad'},
          Decimal.parse('5'),
          amountType: 'try',
        ),
        Decimal.parse('5'),
      );
      expect(
        ScenarioReplayParser.dcaPeriodicAmount(
          {
            'schemaVersion': ScenarioReplayParser.currentSchemaVersion,
            'periodicAmount': 'bad',
          },
          Decimal.parse('5'),
          amountType: 'try',
        ),
        isNull,
      );
      expect(
        ScenarioReplayParser.dcaPeriodicAmount(
          {
            'schemaVersion': ScenarioReplayParser.currentSchemaVersion,
            'periodicAmount': '6',
          },
          Decimal.parse('5'),
          amountType: 'try',
        ),
        isNull,
        reason: 'v2 top-level amount ile redundant periodicAmount eşleşmeli',
      );
      expect(
        ScenarioReplayParser.dcaPeriodicAmount(
          {'periodicAmount': '1.001'},
          Decimal.parse('5'),
          amountType: 'try',
        ),
        Decimal.parse('5'),
      );
    },
  );
}
