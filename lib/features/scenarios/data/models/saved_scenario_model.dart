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
    final type = json['type'];
    final label = json['label'];
    final extraData = json['extraData'];
    return SavedScenarioModel(
      id: _requireString(json['id'], 'id'),
      // type non-String ise (`as String?` TypeError atardı) null geç →
      // _parseType default'una (whatIf) düşsün.
      type: _parseType(type is String ? type : null),
      assetSymbol: _requireString(json['assetSymbol'], 'assetSymbol'),
      assetDisplayName: _requireString(
        json['assetDisplayName'],
        'assetDisplayName',
      ),
      buyDate: _parseDate(json['buyDate']),
      sellDate: json['sellDate'] != null ? _parseDate(json['sellDate']) : null,
      amount: MoneyParser.requireDecimal(json['amount'], 'amount'),
      amountType: _requireString(json['amountType'], 'amountType'),
      label: label is String ? label : null,
      createdAt: _parseDate(json['createdAt']),
      // Map değilse null; non-String key'leri toString ile güvenle çevir.
      extraData: extraData is Map
          ? extraData.map((k, v) => MapEntry(k.toString(), v))
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
  /// ("yyyy-MM-dd") biçimlerini güvenle ele alır.
  ///
  /// **Silent rollover koruması:** `DateTime(2020, 13, 45)` hata atmaz,
  /// sessizce `2021-02-14`'e kayar. Date-only yolunda bileşenler parse edilip
  /// round-trip ile doğrulanır (DateTime.tryParse de "2020-02-30"u rollover
  /// edebildiği için ISO-only timestamp dışında ona güvenilmez). Geçersizde
  /// raw RangeError yerine açıklayıcı `FormatException`.
  static DateTime _parseDate(Object? value) {
    if (value is! String) {
      throw FormatException('saved scenario: tarih string değil ($value)');
    }
    // ISO timestamp (createdAt) — saat/tz içerir, tryParse uygun.
    if (value.contains('T')) {
      final ts = DateTime.tryParse(value);
      if (ts != null) return ts;
      throw FormatException('saved scenario: geçersiz timestamp ($value)');
    }
    // Date-only "yyyy-MM-dd": parça + aralık doğrulaması (rollover'ı yakala).
    final parts = value.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        final dt = DateTime(y, m, d);
        if (dt.year == y && dt.month == m && dt.day == d) return dt;
      }
    }
    throw FormatException('saved scenario: geçersiz tarih ($value)');
  }
}
