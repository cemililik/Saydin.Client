import 'package:saydin/features/comparison/domain/entities/compare_result.dart';
import 'package:saydin/features/what_if/data/models/what_if_response_model.dart';

class CompareResultModel extends CompareResult {
  const CompareResultModel({required super.results});

  factory CompareResultModel.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    if (rawResults is! List<dynamic>) {
      throw const FormatException(
        'compare result: "results" alanı liste değil',
      );
    }
    final items = rawResults.map((e) {
      if (e is! Map<Object?, Object?>) {
        throw const FormatException('compare result item: map değil');
      }
      final rank = e['rank'];
      final calc = e['calculation'];
      if (rank is! num || calc is! Map<Object?, Object?>) {
        throw const FormatException(
          'compare result item: rank int veya calculation map değil',
        );
      }
      return CompareResultItem(
        rank: rank.toInt(),
        calculation: WhatIfResponseModel.fromJson(
          Map<String, dynamic>.from(calc),
        ),
      );
    }).toList();
    return CompareResultModel(results: items);
  }
}
