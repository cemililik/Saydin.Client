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

  @override
  List<Object?> get props => [symbol, displayName, category];
}
