import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

/// Senaryo duplicate kontrolü için yalnız yeniden-hesaplama girdilerini içeren
/// versioned ve deterministik kimlik üretir. Sonuç/etiket alanları (winner,
/// totalReturn, displayName vb.) bilerek dışarıda bırakılır.
class ScenarioInputFingerprint {
  const ScenarioInputFingerprint._();

  static const int version = 2;

  static String fromScenario(SavedScenario scenario) => fromValues(
    type: scenario.type,
    assetSymbol: scenario.assetSymbol,
    buyDate: scenario.buyDate,
    sellDate: scenario.sellDate,
    amount: scenario.amount,
    amountType: scenario.amountType,
    extraData: scenario.extraData,
  );

  static String fromValues({
    required ScenarioType type,
    required String assetSymbol,
    required DateTime buyDate,
    required DateTime? sellDate,
    required Decimal amount,
    required String amountType,
    required Map<String, dynamic>? extraData,
  }) {
    final body = <String, Object?>{
      'fingerprintVersion': version,
      'type': type.name,
      'asset': type == ScenarioType.comparison
          ? _comparisonSymbols(assetSymbol)
          : assetSymbol,
      'buyDate': _date(buyDate),
      'sellDate': sellDate == null ? null : _date(sellDate),
      'amount': amount.toString(),
      'amountType': amountType,
      'input': switch (type) {
        ScenarioType.whatIf => {
          'mode': extraData?['mode'] == 'reverse' ? 'reverse' : 'normal',
          'includeInflation': extraData?['includeInflation'] == true,
        },
        ScenarioType.comparison => {
          'includeInflation': extraData?['includeInflation'] == true,
        },
        ScenarioType.portfolio => {
          'items': _portfolioItems(extraData?['items']),
          'includeInflation': extraData?['includeInflation'] == true,
        },
        ScenarioType.dca => {
          'period': extraData?['period'] == 'weekly' ? 'weekly' : 'monthly',
          'includeInflation': extraData?['includeInflation'] == true,
        },
      },
    };
    return jsonEncode(body);
  }

  static List<String> _comparisonSymbols(String value) {
    final symbols =
        value
            .split(',')
            .map((symbol) => symbol.trim())
            .where((symbol) => symbol.isNotEmpty)
            .toList(growable: false)
          ..sort();
    return symbols;
  }

  static List<Map<String, String?>> _portfolioItems(Object? value) {
    if (value is! List<dynamic>) return const [];
    final items = value
        .map((raw) {
          if (raw is! Map<Object?, Object?>) {
            return <String, String?>{'invalid': raw.runtimeType.toString()};
          }
          final amount = MoneyParser.tryDecimal(raw['amount']);
          final assetSymbol = raw['assetSymbol'];
          final amountType = raw['amountType'];
          return <String, String?>{
            'assetSymbol': assetSymbol is String ? assetSymbol : null,
            'amount': amount?.toString(),
            'amountType': amountType is String ? amountType : null,
          };
        })
        .toList(growable: false);
    items.sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
    return items;
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
