import 'package:equatable/equatable.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';

class DcaFormInput extends Equatable {
  final String? selectedSymbol;
  final DateTime? startDate;
  final DateTime? endDate;
  final String period;
  final String amountType;
  final bool includeInflation;
  final num? periodicAmount;

  const DcaFormInput({
    this.selectedSymbol,
    this.startDate,
    this.endDate,
    this.period = 'monthly',
    this.amountType = 'try',
    this.includeInflation = false,
    this.periodicAmount,
  });

  DcaFormInput copyWith({
    String? selectedSymbol,
    DateTime? startDate,
    DateTime? endDate,
    String? period,
    String? amountType,
    bool? includeInflation,
    num? periodicAmount,
  }) => DcaFormInput(
    selectedSymbol: selectedSymbol ?? this.selectedSymbol,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    period: period ?? this.period,
    amountType: amountType ?? this.amountType,
    includeInflation: includeInflation ?? this.includeInflation,
    periodicAmount: periodicAmount ?? this.periodicAmount,
  );

  @override
  List<Object?> get props => [
    selectedSymbol,
    startDate,
    endDate,
    period,
    amountType,
    includeInflation,
    periodicAmount,
  ];
}

sealed class DcaState extends Equatable {
  final DcaFormInput formInput;

  const DcaState({this.formInput = const DcaFormInput()});

  @override
  List<Object?> get props => [formInput];
}

class DcaInitial extends DcaState {
  const DcaInitial();
}

class DcaAssetsLoading extends DcaState {
  const DcaAssetsLoading();
}

class DcaAssetsLoaded extends DcaState {
  final List<Asset> assets;

  const DcaAssetsLoaded(this.assets, {super.formInput});

  DcaAssetsLoaded copyWith({DcaFormInput? formInput}) =>
      DcaAssetsLoaded(assets, formInput: formInput ?? this.formInput);

  @override
  List<Object?> get props => [assets, formInput];
}

class DcaCalculating extends DcaState {
  final List<Asset> assets;

  const DcaCalculating(this.assets, {super.formInput});

  @override
  List<Object?> get props => [assets, formInput];
}

class DcaSuccess extends DcaState {
  final List<Asset> assets;
  final DcaResult result;

  const DcaSuccess({
    required this.assets,
    required this.result,
    super.formInput,
  });

  DcaSuccess copyWith({DcaFormInput? formInput}) => DcaSuccess(
    assets: assets,
    result: result,
    formInput: formInput ?? this.formInput,
  );

  @override
  List<Object?> get props => [assets, result, formInput];
}

class DcaFailure extends DcaState {
  final List<Asset> assets;
  final AppError error;

  const DcaFailure({
    required this.assets,
    required this.error,
    super.formInput,
  });

  DcaFailure copyWith({DcaFormInput? formInput}) => DcaFailure(
    assets: assets,
    error: error,
    formInput: formInput ?? this.formInput,
  );

  @override
  List<Object?> get props => [assets, error, formInput];
}
