import '../../domain/entities/asset.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.symbol,
    required super.displayName,
    required super.category,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
        symbol: json['symbol'] as String,
        displayName: json['displayName'] as String,
        category: json['category'] as String,
      );
}
