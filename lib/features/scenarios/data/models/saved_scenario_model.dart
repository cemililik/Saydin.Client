import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart';

class SavedScenarioModel extends SavedScenario {
  const SavedScenarioModel({
    required super.id,
    super.type = ScenarioType.whatIf,
    required super.assetSymbol,
    required super.assetDisplayName,
    required super.buyDate,
    super.sellDate,
    required super.amount,
    required super.amountType,
    super.label,
    required super.createdAt,
    super.extraData,
  });

  factory SavedScenarioModel.fromJson(Map<String, dynamic> json) {
    return SavedScenarioModel(
      id: _requireString(json['id'], 'id'),
      type: _parseType(json['type'] as String?),
      assetSymbol: _requireString(json['assetSymbol'], 'assetSymbol'),
      assetDisplayName: _requireString(
        json['assetDisplayName'],
        'assetDisplayName',
      ),
      buyDate: _parseDate(json['buyDate']),
      sellDate: json['sellDate'] != null ? _parseDate(json['sellDate']) : null,
      amount: MoneyParser.requireDecimal(json['amount'], 'amount'),
      amountType: _requireString(json['amountType'], 'amountType'),
      label: json['label'] as String?,
      createdAt: _parseDate(json['createdAt']),
      extraData: json['extraData'] != null
          ? Map<String, dynamic>.from(json['extraData'] as Map)
          : null,
    );
  }

  /// Blind `as String` yerine tip-güvenli string okuma — yanlış tip için
  /// temiz `FormatException` (raw TypeError değil). DcaResponseModel paterni.
  static String _requireString(Object? value, String field) {
    if (value is String) return value;
    throw FormatException('saved scenario: $field string değil ($value)');
  }

  /// `ScenariosRepositoryImpl._typeToString` ile **simetrik** olmalı.
  /// `'what_if'` case'i explicit; default'a düşmek backend'in bilinmeyen
  /// bir type döndürmesini sessiz veri kaybına dönüştürürdü.
  static ScenarioType _parseType(String? value) => switch (value) {
    'what_if' => ScenarioType.whatIf,
    'comparison' => ScenarioType.comparison,
    'portfolio' => ScenarioType.portfolio,
    'dca' => ScenarioType.dca,
    _ => ScenarioType.whatIf,
  };

  /// Tarih parse — `createdAt` (ISO timestamp) ve `buyDate/sellDate`
  /// ("yyyy-MM-dd") biçimlerini güvenle ele alır. Önce `DateTime.tryParse`,
  /// sonra parça-bazlı `int.tryParse` (uzunluk kontrollü). Geçersizde raw
  /// RangeError/FormatException yerine açıklayıcı `FormatException`.
  static DateTime _parseDate(Object? value) {
    if (value is! String) {
      throw FormatException('saved scenario: tarih string değil ($value)');
    }
    final iso = DateTime.tryParse(value);
    if (iso != null) return iso;
    final parts = value.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
    throw FormatException('saved scenario: geçersiz tarih ($value)');
  }
}
