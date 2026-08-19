import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';
import 'package:saydin/features/scenarios/domain/scenario_input_fingerprint.dart';

String fingerprint(
  ScenarioType type, {
  String asset = 'USDTRY',
  Map<String, dynamic>? extraData,
}) => ScenarioInputFingerprint.fromValues(
  type: type,
  assetSymbol: asset,
  buyDate: DateTime(2024, 1, 1),
  sellDate: DateTime(2025, 1, 1),
  amount: Decimal.fromInt(1000),
  amountType: 'try',
  extraData: extraData,
);

void main() {
  test('DCA weekly ve monthly farklı input fingerprint üretir', () {
    expect(
      fingerprint(ScenarioType.dca, extraData: const {'period': 'weekly'}),
      isNot(
        fingerprint(ScenarioType.dca, extraData: const {'period': 'monthly'}),
      ),
    );
  });

  test('enflasyon tercihi finansal input fingerprintine dahildir', () {
    expect(
      fingerprint(
        ScenarioType.whatIf,
        extraData: const {'includeInflation': false},
      ),
      isNot(
        fingerprint(
          ScenarioType.whatIf,
          extraData: const {'includeInflation': true},
        ),
      ),
    );
  });

  test('farklı portföy dağılımları aynı toplamda duplicate sayılmaz', () {
    final first = fingerprint(
      ScenarioType.portfolio,
      asset: 'PORTFOLIO',
      extraData: const {
        'items': [
          {'assetSymbol': 'USDTRY', 'amount': '500', 'amountType': 'try'},
          {'assetSymbol': 'XAU', 'amount': '500', 'amountType': 'try'},
        ],
      },
    );
    final second = fingerprint(
      ScenarioType.portfolio,
      asset: 'PORTFOLIO',
      extraData: const {
        'items': [
          {'assetSymbol': 'USDTRY', 'amount': '750', 'amountType': 'try'},
          {'assetSymbol': 'XAU', 'amount': '250', 'amountType': 'try'},
        ],
      },
    );

    expect(first, isNot(second));
  });

  test(
    'portföy kalem sırası ve result-only alanı fingerprinti değiştirmez',
    () {
      final first = fingerprint(
        ScenarioType.portfolio,
        asset: 'PORTFOLIO',
        extraData: const {
          'totalReturn': 12.3,
          'items': [
            {'assetSymbol': 'USDTRY', 'amount': '500.0', 'amountType': 'try'},
            {'assetSymbol': 'XAU', 'amount': '500', 'amountType': 'try'},
          ],
        },
      );
      final second = fingerprint(
        ScenarioType.portfolio,
        asset: 'PORTFOLIO',
        extraData: const {
          'totalReturn': 99.9,
          'items': [
            {'assetSymbol': 'XAU', 'amount': 500, 'amountType': 'try'},
            {'assetSymbol': 'USDTRY', 'amount': '500', 'amountType': 'try'},
          ],
        },
      );

      expect(first, second);
    },
  );

  test('comparison sembol sırası aynı input seti için canonicaldır', () {
    expect(
      fingerprint(ScenarioType.comparison, asset: 'USDTRY,XAU'),
      fingerprint(ScenarioType.comparison, asset: 'XAU,USDTRY'),
    );
  });
}
