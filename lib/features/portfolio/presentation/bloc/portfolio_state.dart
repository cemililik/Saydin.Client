import 'package:equatable/equatable.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';

sealed class PortfolioState extends Equatable {
  final List<Asset> assets;
  final List<PortfolioItem> items;
  final DateTime? buyDate;
  final DateTime? sellDate;
  final bool includeInflation;

  const PortfolioState({
    this.assets = const [],
    this.items = const [],
    this.buyDate,
    this.sellDate,
    this.includeInflation = false,
  });

  @override
  List<Object?> get props => [
    assets,
    items,
    buyDate,
    sellDate,
    includeInflation,
  ];
}

final class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

final class PortfolioAssetsLoading extends PortfolioState {
  const PortfolioAssetsLoading({
    super.assets,
    super.items,
    super.buyDate,
    super.sellDate,
    super.includeInflation,
  });
}

final class PortfolioEditing extends PortfolioState {
  const PortfolioEditing({
    super.assets,
    super.items,
    super.buyDate,
    super.sellDate,
    super.includeInflation,
  });
}

final class PortfolioCalculating extends PortfolioState {
  const PortfolioCalculating({
    super.assets,
    required super.items,
    super.buyDate,
    super.sellDate,
    super.includeInflation,
  });
}

final class PortfolioSuccess extends PortfolioState {
  final PortfolioResult result;

  const PortfolioSuccess({
    super.assets,
    required super.items,
    super.buyDate,
    super.sellDate,
    super.includeInflation,
    required this.result,
  });

  @override
  List<Object?> get props => [...super.props, result];
}

final class PortfolioFailure extends PortfolioState {
  final AppError error;

  const PortfolioFailure({
    super.assets,
    required super.items,
    super.buyDate,
    super.sellDate,
    super.includeInflation,
    required this.error,
  });

  @override
  List<Object?> get props => [...super.props, error];
}
