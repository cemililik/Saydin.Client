import 'package:equatable/equatable.dart';

class Asset extends Equatable {
  static const categoryPreciousMetal = 'precious_metal';

  final String symbol;
  final String displayName;
  final String category;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const Asset({
    required this.symbol,
    required this.displayName,
    required this.category,
    this.firstDate,
    this.lastDate,
  });

  /// Bu asset için geçerli tutar tipleri.
  List<String> get allowedAmountTypes => switch (category) {
    Asset.categoryPreciousMetal => ['try', 'grams'],
    _ => ['try', 'units'],
  };

  @override
  List<Object?> get props => [
    symbol,
    displayName,
    category,
    firstDate,
    lastDate,
  ];
}
