import 'package:equatable/equatable.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';

class CompareResultItem extends Equatable {
  final int rank;
  final WhatIfResult calculation;

  const CompareResultItem({required this.rank, required this.calculation});

  @override
  List<Object?> get props => [rank, calculation];
}

class CompareResult extends Equatable {
  final List<CompareResultItem> results;

  const CompareResult({required this.results});

  @override
  List<Object?> get props => [results];
}
