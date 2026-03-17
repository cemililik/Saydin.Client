import 'package:equatable/equatable.dart';

sealed class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

class PortfolioAssetsRequested extends PortfolioEvent {
  const PortfolioAssetsRequested();
}

class PortfolioBuyDateChanged extends PortfolioEvent {
  final DateTime? date;
  const PortfolioBuyDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class PortfolioSellDateChanged extends PortfolioEvent {
  final DateTime? date;
  const PortfolioSellDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class PortfolioItemAdded extends PortfolioEvent {
  final String assetSymbol;
  final String assetDisplayName;
  final num amount;
  final String amountType;

  const PortfolioItemAdded({
    required this.assetSymbol,
    required this.assetDisplayName,
    required this.amount,
    required this.amountType,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    assetDisplayName,
    amount,
    amountType,
  ];
}

class PortfolioItemRemoved extends PortfolioEvent {
  final String id;
  const PortfolioItemRemoved(this.id);

  @override
  List<Object?> get props => [id];
}

class PortfolioCalculateRequested extends PortfolioEvent {
  const PortfolioCalculateRequested();
}

class PortfolioReset extends PortfolioEvent {
  const PortfolioReset();
}
