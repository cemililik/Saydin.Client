import '../../domain/entities/asset.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.symbol,
    required super.displayName,
    required super.category,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    final symbol = json['symbol'];
    final displayName = json['displayName'];
    final category = json['category'];
    if (symbol is! String || displayName is! String || category is! String) {
      throw FormatException(
        'AssetModel.fromJson: beklenen alanlar eksik veya yanlış tipte. '
        'symbol=$symbol, displayName=$displayName, category=$category',
      );
    }
    return AssetModel(
      symbol: symbol,
      displayName: displayName,
      category: category,
    );
  }
}
