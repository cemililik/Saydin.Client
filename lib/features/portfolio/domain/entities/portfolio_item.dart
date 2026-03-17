import 'package:equatable/equatable.dart';

/// Portföydeki tek bir varlık kalemi (henüz hesaplanmamış girdi).
class PortfolioItem extends Equatable {
  final String id; // client-side benzersiz kimlik
  final String assetSymbol;
  final String assetDisplayName;
  final num amount;
  final String amountType; // 'try' | 'units' | 'grams'

  const PortfolioItem({
    required this.id,
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.amount,
    required this.amountType,
  });

  @override
  List<Object?> get props => [
    id,
    assetSymbol,
    assetDisplayName,
    amount,
    amountType,
  ];
}
