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
    if (rawResults.isEmpty) {
      throw const FormatException('compare result: sonuç listesi boş');
    }
    final items = rawResults.indexed
        .map((entry) {
          final expectedRank = entry.$1 + 1;
          final e = entry.$2;
          if (e is! Map<Object?, Object?>) {
            throw const FormatException('compare result item: map değil');
          }
          final rank = e['rank'];
          final calc = e['calculation'];
          if (rank is! int || calc is! Map<Object?, Object?>) {
            throw const FormatException(
              'compare result item: rank int veya calculation map değil',
            );
          }
          if (rank != expectedRank) {
            throw FormatException(
              'compare result item: rank sırası bozuk '
              '(beklenen $expectedRank, gelen $rank)',
            );
          }
          return CompareResultItem(
            rank: rank,
            calculation: WhatIfResponseModel.fromJson(
              Map<String, dynamic>.from(calc),
            ),
          );
        })
        .toList(growable: false);
    return CompareResultModel(results: items);
  }
}
