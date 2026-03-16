import '../entities/asset.dart';
import '../repositories/what_if_repository.dart';

class GetAssets {
  final WhatIfRepository _repository;
  GetAssets(this._repository);

  Future<List<Asset>> call() => _repository.getAssets();
}
