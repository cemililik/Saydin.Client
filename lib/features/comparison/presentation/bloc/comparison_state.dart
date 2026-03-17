import 'package:equatable/equatable.dart';
import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';

abstract class ComparisonState extends Equatable {
  final List<Asset> assets;
  final List<String> selectedSymbols;
  final DateTime? buyDate;
  final DateTime? sellDate;
  final num? amount;
  final String amountType;
  final bool includeInflation;

  const ComparisonState({
    this.assets = const [],
    this.selectedSymbols = const [],
    this.buyDate,
    this.sellDate,
    this.amount,
    this.amountType = 'try',
    this.includeInflation = false,
  });

  @override
  List<Object?> get props => [
    assets,
    selectedSymbols,
    buyDate,
    sellDate,
    amount,
    amountType,
    includeInflation,
  ];
}

class ComparisonInitial extends ComparisonState {
  const ComparisonInitial();
}

class ComparisonAssetsLoading extends ComparisonState {
  const ComparisonAssetsLoading();
}

class ComparisonAssetsLoaded extends ComparisonState {
  const ComparisonAssetsLoaded({
    required super.assets,
    super.selectedSymbols,
    super.buyDate,
    super.sellDate,
    super.amount,
    super.amountType,
    super.includeInflation,
  });

  ComparisonAssetsLoaded copyWith({
    List<Asset>? assets,
    List<String>? selectedSymbols,
    DateTime? buyDate,
    Object? sellDate = _sentinel,
    num? amount,
    String? amountType,
    bool? includeInflation,
  }) {
    return ComparisonAssetsLoaded(
      assets: assets ?? this.assets,
      selectedSymbols: selectedSymbols ?? this.selectedSymbols,
      buyDate: buyDate ?? this.buyDate,
      sellDate: sellDate == _sentinel ? this.sellDate : sellDate as DateTime?,
      amount: amount ?? this.amount,
      amountType: amountType ?? this.amountType,
      includeInflation: includeInflation ?? this.includeInflation,
    );
  }
}

class ComparisonCalculating extends ComparisonState {
  const ComparisonCalculating({
    required super.assets,
    required super.selectedSymbols,
    super.buyDate,
    super.sellDate,
    super.amount,
    super.amountType,
    super.includeInflation,
  });
}

class ComparisonSuccess extends ComparisonState {
  final CompareResult result;

  const ComparisonSuccess({
    required super.assets,
    required super.selectedSymbols,
    super.buyDate,
    super.sellDate,
    super.amount,
    super.amountType,
    super.includeInflation,
    required this.result,
  });

  @override
  List<Object?> get props => [...super.props, result];
}

class ComparisonFailure extends ComparisonState {
  final String message;

  const ComparisonFailure({
    required super.assets,
    required super.selectedSymbols,
    super.buyDate,
    super.sellDate,
    super.amount,
    super.amountType,
    super.includeInflation,
    required this.message,
  });

  @override
  List<Object?> get props => [...super.props, message];
}

const _sentinel = Object();
