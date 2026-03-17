import '../../domain/entities/asset.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.symbol,
    required super.displayName,
    required super.category,
    super.firstDate,
    super.lastDate,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    final symbol = json['symbol'];
    final displayName = json['displayName'];
    final categoryRaw = json['category'];
    if (symbol is! String || displayName is! String || categoryRaw == null) {
      throw FormatException(
        'AssetModel.fromJson: beklenen alanlar eksik veya yanlış tipte. '
        'symbol=$symbol, displayName=$displayName, category=$categoryRaw',
      );
    }
    return AssetModel(
      symbol: symbol,
      displayName: displayName,
      category: categoryRaw.toString(),
      firstDate: _tryParseDate(json['firstPriceDate']),
      lastDate: _tryParseDate(json['lastPriceDate']),
    );
  }

  static DateTime? _tryParseDate(Object? value) {
    if (value is! String) return null;
    try {
      return DateTime.parse(value);
    } on FormatException {
      return null;
    }
  }
}
