import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

class SavedScenarioModel extends SavedScenario {
  const SavedScenarioModel({
    required super.id,
    required super.assetSymbol,
    required super.assetDisplayName,
    required super.buyDate,
    super.sellDate,
    required super.amount,
    required super.amountType,
    super.label,
    required super.createdAt,
  });

  factory SavedScenarioModel.fromJson(Map<String, dynamic> json) {
    return SavedScenarioModel(
      id: json['id'] as String,
      assetSymbol: json['assetSymbol'] as String,
      assetDisplayName: json['assetDisplayName'] as String,
      buyDate: _parseDate(json['buyDate'] as String),
      sellDate: json['sellDate'] != null
          ? _parseDate(json['sellDate'] as String)
          : null,
      amount: json['amount'] as num,
      amountType: json['amountType'] as String,
      label: json['label'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static DateTime _parseDate(String value) {
    final parts = value.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
