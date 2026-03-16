import 'package:equatable/equatable.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

abstract class WhatIfState extends Equatable {
  const WhatIfState();
  @override
  List<Object?> get props => [];
}

class WhatIfInitial extends WhatIfState {
  const WhatIfInitial();
}

class WhatIfAssetsLoading extends WhatIfState {
  const WhatIfAssetsLoading();
}

class WhatIfAssetsLoaded extends WhatIfState {
  final List<Asset> assets;
  WhatIfAssetsLoaded(List<Asset> assets) : assets = List.unmodifiable(assets);
  @override
  List<Object?> get props => [assets];
}

class WhatIfCalculating extends WhatIfState {
  final List<Asset> assets;
  WhatIfCalculating(List<Asset> assets) : assets = List.unmodifiable(assets);
  @override
  List<Object?> get props => [assets];
}

class WhatIfSuccess extends WhatIfState {
  final List<Asset> assets;
  final WhatIfResult result;
  WhatIfSuccess({required List<Asset> assets, required this.result})
    : assets = List.unmodifiable(assets);
  @override
  List<Object?> get props => [assets, result];
}

class WhatIfFailure extends WhatIfState {
  final List<Asset> assets;
  final AppError error;
  WhatIfFailure({required List<Asset> assets, required this.error})
    : assets = List.unmodifiable(assets);
  @override
  List<Object?> get props => [assets, error];
}
