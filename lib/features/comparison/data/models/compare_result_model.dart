import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/what_if/data/models/what_if_response_model.dart';

class CompareResultModel extends CompareResult {
  const CompareResultModel({required super.results});

  factory CompareResultModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    final items = rawResults.map((e) {
      final map = e as Map<String, dynamic>;
      return CompareResultItem(
        rank: map['rank'] as int,
        calculation: WhatIfResponseModel.fromJson(
          map['calculation'] as Map<String, dynamic>,
        ),
      );
    }).toList();
    return CompareResultModel(results: items);
  }
}
