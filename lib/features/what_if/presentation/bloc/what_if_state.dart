import 'package:equatable/equatable.dart';
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
  const WhatIfAssetsLoaded(this.assets);
  @override
  List<Object?> get props => [assets];
}

class WhatIfCalculating extends WhatIfState {
  final List<Asset> assets;
  const WhatIfCalculating(this.assets);
  @override
  List<Object?> get props => [assets];
}

class WhatIfSuccess extends WhatIfState {
  final List<Asset> assets;
  final WhatIfResult result;
  const WhatIfSuccess({required this.assets, required this.result});
  @override
  List<Object?> get props => [assets, result];
}

class WhatIfFailure extends WhatIfState {
  final List<Asset> assets;
  final String message;
  const WhatIfFailure({required this.assets, required this.message});
  @override
  List<Object?> get props => [assets, message];
}
