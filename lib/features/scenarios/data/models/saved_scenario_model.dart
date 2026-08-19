import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/core/utils/scenario_replay_parser.dart';
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
    // Type önce doğrulanır: bilinmeyen bir backend tipi what-if gibi
    // yorumlanıp farklı semantikte replay edilmemeli.
    final type = _parseType(json['type']);
    final label = json['label'];
    final extraData = _parseExtraData(json['extraData']);
    return SavedScenarioModel(
      id: _requireString(json['id'], 'id'),
      type: type,
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
      extraData: extraData,
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
  static ScenarioType _parseType(Object? value) => switch (value) {
    'what_if' => ScenarioType.whatIf,
    'comparison' => ScenarioType.comparison,
    'portfolio' => ScenarioType.portfolio,
    'dca' => ScenarioType.dca,
    String() => throw FormatException(
      'saved scenario: bilinmeyen type ($value)',
    ),
    _ => throw FormatException('saved scenario: type string değil ($value)'),
  };

  /// JSON dışındaki Map/key tiplerini ve desteklenmeyen replay şemalarını veri
  /// sınırında reddeder. `null` ve version alanı olmayan map'ler legacy v1
  /// uyumluluğu için geçerlidir.
  static Map<String, dynamic>? _parseExtraData(Object? value) {
    if (value == null) return null;
    if (value is! Map<Object?, Object?>) {
      throw FormatException('saved scenario: extraData map değil ($value)');
    }

    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException(
          'saved scenario: extraData anahtarı string değil ($key)',
        );
      }
      result[key] = entry.value;
    }

    if (!ScenarioReplayParser.hasSupportedSchema(result)) {
      throw FormatException(
        'saved scenario: desteklenmeyen extraData schemaVersion '
        '(${result['schemaVersion']})',
      );
    }
    return result;
  }

  /// Tarih parse — `createdAt` (ISO timestamp) ve `buyDate/sellDate`
  /// ("yyyy-MM-dd") biçimlerini güvenle ele alır.
  ///
  /// **Silent rollover koruması:** `DateTime(2020, 13, 45)` hata atmaz,
  /// sessizce `2021-02-14`'e kayar. Date-only yolunda bileşenler parse edilip
  /// round-trip ile doğrulanır (DateTime.tryParse de "2020-02-30"u rollover
  /// edebildiği için ISO-only timestamp dışında ona güvenilmez). Geçersizde
  /// raw RangeError yerine açıklayıcı `FormatException`.
  static final _dateOnlyPattern = RegExp(r'^\d{1,4}-\d{1,2}-\d{1,2}$');

  static DateTime _parseDate(Object? value) {
    if (value is! String) {
      throw FormatException('saved scenario: tarih string değil ($value)');
    }
    // Salt "yyyy-MM-dd" (buyDate/sellDate): parça + aralık doğrulaması.
    // DateTime.tryParse "2020-13-45"i sessizce kaydırabildiği için bu biçimde
    // ona güvenmeyiz; round-trip ile rollover'ı yakalarız.
    if (_dateOnlyPattern.hasMatch(value)) {
      final parts = value.split('-');
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        final dt = DateTime(y, m, d);
        if (dt.year == y && dt.month == m && dt.day == d) return dt;
      }
      throw FormatException('saved scenario: geçersiz tarih ($value)');
    }
    // Timestamp (createdAt) — 'T'- VEYA boşluk-ayraçlı ISO, offset/tz dahil.
    // tryParse her ikisini de tolere eder (DateTime.parse uyumlu davranış).
    final ts = DateTime.tryParse(value);
    if (ts != null) return ts;
    throw FormatException('saved scenario: geçersiz tarih ($value)');
  }
}
