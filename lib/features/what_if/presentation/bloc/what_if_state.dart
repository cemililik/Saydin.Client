import 'package:equatable/equatable.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

enum CalculationMode { normal, reverse }

/// Form alanlarının BLoC içindeki anlık değerleri.
class WhatIfFormInput extends Equatable {
  final String? selectedSymbol;
  final DateTime? buyDate;
  final DateTime? sellDate;
  final String amountType;
  final num? amount;
  final bool includeInflation;
  final CalculationMode calculationMode;

  /// Sembol değiştiğinde seçili tarihler asset aralığı dışındaysa
  /// otomatik sıkıştırıldı — bir kez gösterildikten sonra sıfırlanır.
  final bool dateAdjusted;

  const WhatIfFormInput({
    this.selectedSymbol,
    this.buyDate,
    this.sellDate,
    this.amountType = 'try',
    this.amount,
    this.includeInflation = false,
    this.calculationMode = CalculationMode.normal,
    this.dateAdjusted = false,
  });

  WhatIfFormInput copyWith({
    Object? selectedSymbol = _sentinel,
    Object? buyDate = _sentinel,
    Object? sellDate = _sentinel,
    String? amountType,
    Object? amount = _sentinel,
    bool? includeInflation,
    CalculationMode? calculationMode,
    bool dateAdjusted = false,
  }) {
    return WhatIfFormInput(
      selectedSymbol: identical(selectedSymbol, _sentinel)
          ? this.selectedSymbol
          : selectedSymbol as String?,
      buyDate: identical(buyDate, _sentinel)
          ? this.buyDate
          : buyDate as DateTime?,
      sellDate: identical(sellDate, _sentinel)
          ? this.sellDate
          : sellDate as DateTime?,
      amountType: amountType ?? this.amountType,
      amount: identical(amount, _sentinel) ? this.amount : amount as num?,
      includeInflation: includeInflation ?? this.includeInflation,
      calculationMode: calculationMode ?? this.calculationMode,
      dateAdjusted: dateAdjusted,
    );
  }

  @override
  List<Object?> get props => [
    selectedSymbol,
    buyDate,
    sellDate,
    amountType,
    amount,
    includeInflation,
    calculationMode,
    dateAdjusted,
  ];
}

// Sentinel değer: nullable alanlar için copyWith'te "değiştirilmedi" işareti.
const _sentinel = Object();

abstract class WhatIfState extends Equatable {
  const WhatIfState();

  WhatIfFormInput get formInput;

  @override
  List<Object?> get props => [];
}

class WhatIfInitial extends WhatIfState {
  const WhatIfInitial();

  @override
  WhatIfFormInput get formInput => const WhatIfFormInput();
}

class WhatIfAssetsLoading extends WhatIfState {
  const WhatIfAssetsLoading();

  @override
  WhatIfFormInput get formInput => const WhatIfFormInput();
}

class WhatIfAssetsLoaded extends WhatIfState {
  final List<Asset> assets;
  @override
  final WhatIfFormInput formInput;

  WhatIfAssetsLoaded(
    List<Asset> assets, {
    this.formInput = const WhatIfFormInput(),
  }) : assets = List.unmodifiable(assets);

  WhatIfAssetsLoaded copyWith({WhatIfFormInput? formInput}) =>
      WhatIfAssetsLoaded(assets, formInput: formInput ?? this.formInput);

  @override
  List<Object?> get props => [assets, formInput];
}

class WhatIfCalculating extends WhatIfState {
  final List<Asset> assets;
  @override
  final WhatIfFormInput formInput;

  WhatIfCalculating(List<Asset> assets, {required this.formInput})
    : assets = List.unmodifiable(assets);

  @override
  List<Object?> get props => [assets, formInput];
}

class WhatIfSuccess extends WhatIfState {
  final List<Asset> assets;
  final WhatIfResult? result;
  final ReverseWhatIfResult? reverseResult;
  @override
  final WhatIfFormInput formInput;

  WhatIfSuccess({
    required List<Asset> assets,
    this.result,
    this.reverseResult,
    required this.formInput,
  }) : assets = List.unmodifiable(assets);

  WhatIfSuccess copyWith({WhatIfFormInput? formInput}) => WhatIfSuccess(
    assets: assets,
    result: result,
    reverseResult: reverseResult,
    formInput: formInput ?? this.formInput,
  );

  @override
  List<Object?> get props => [assets, result, reverseResult, formInput];
}

class WhatIfFailure extends WhatIfState {
  final List<Asset> assets;
  final AppError error;
  @override
  final WhatIfFormInput formInput;

  WhatIfFailure({
    required List<Asset> assets,
    required this.error,
    required this.formInput,
  }) : assets = List.unmodifiable(assets);

  WhatIfFailure copyWith({WhatIfFormInput? formInput}) => WhatIfFailure(
    assets: assets,
    error: error,
    formInput: formInput ?? this.formInput,
  );

  @override
  List<Object?> get props => [assets, error, formInput];
}
