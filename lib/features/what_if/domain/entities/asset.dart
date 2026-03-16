import 'package:equatable/equatable.dart';

class Asset extends Equatable {
  final String symbol;
  final String displayName;
  final String category;

  const Asset({
    required this.symbol,
    required this.displayName,
    required this.category,
  });

  /// Bu asset için geçerli tutar tipleri.
  List<String> get allowedAmountTypes => switch (category) {
    'precious_metal' => ['try', 'grams'],
    _ => ['try', 'units'],
  };

  @override
  List<Object?> get props => [symbol, displayName, category];
}
