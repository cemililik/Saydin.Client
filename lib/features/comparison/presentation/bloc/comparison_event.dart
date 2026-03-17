import 'package:equatable/equatable.dart';

abstract class ComparisonEvent extends Equatable {
  const ComparisonEvent();
  @override
  List<Object?> get props => [];
}

class ComparisonAssetsRequested extends ComparisonEvent {
  const ComparisonAssetsRequested();
}

class ComparisonSymbolToggled extends ComparisonEvent {
  final String symbol;
  const ComparisonSymbolToggled(this.symbol);
  @override
  List<Object?> get props => [symbol];
}

class ComparisonBuyDateChanged extends ComparisonEvent {
  final DateTime date;
  const ComparisonBuyDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class ComparisonSellDateChanged extends ComparisonEvent {
  final DateTime? date;
  const ComparisonSellDateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class ComparisonAmountChanged extends ComparisonEvent {
  final num amount;
  const ComparisonAmountChanged(this.amount);
  @override
  List<Object?> get props => [amount];
}

class ComparisonAmountTypeChanged extends ComparisonEvent {
  final String amountType;
  const ComparisonAmountTypeChanged(this.amountType);
  @override
  List<Object?> get props => [amountType];
}

class ComparisonCalculateRequested extends ComparisonEvent {
  const ComparisonCalculateRequested();
}
