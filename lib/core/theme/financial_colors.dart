import 'package:flutter/material.dart';
import 'package:saydin/core/constants/app_colors.dart';

/// Finansal anlam taşıyan renklerin tema-duyarlı tek kaynağı.
///
/// Bu renkler yalnızca kar/zarar yönünü görsel olarak destekler; kullanıcıya
/// aktarılan bilgi ikon ve metinle de sunulmaya devam eder.
@immutable
class FinancialColors extends ThemeExtension<FinancialColors> {
  final Color profit;
  final Color loss;
  final Color chartCost;
  final List<Color> portfolioPalette;

  const FinancialColors({
    required this.profit,
    required this.loss,
    required this.chartCost,
    required this.portfolioPalette,
  });

  static const light = FinancialColors(
    profit: AppColors.profit,
    loss: AppColors.loss,
    chartCost: Color(0xFF616161),
    portfolioPalette: AppColors.portfolioColors,
  );

  static const dark = FinancialColors(
    profit: AppColors.profitDark,
    loss: AppColors.lossDark,
    chartCost: Color(0xFFBDBDBD),
    portfolioPalette: [
      Color(0xFF64B5F6),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFFBA68C8),
      Color(0xFF4DD0E1),
      Color(0xFFE57373),
      Color(0xFFAED581),
      Color(0xFF9575CD),
    ],
  );

  @override
  FinancialColors copyWith({
    Color? profit,
    Color? loss,
    Color? chartCost,
    List<Color>? portfolioPalette,
  }) => FinancialColors(
    profit: profit ?? this.profit,
    loss: loss ?? this.loss,
    chartCost: chartCost ?? this.chartCost,
    portfolioPalette: portfolioPalette ?? this.portfolioPalette,
  );

  @override
  FinancialColors lerp(covariant FinancialColors? other, double t) {
    if (other == null) return this;
    return FinancialColors(
      profit: Color.lerp(profit, other.profit, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      chartCost: Color.lerp(chartCost, other.chartCost, t)!,
      portfolioPalette: List<Color>.generate(
        portfolioPalette.length,
        (index) => Color.lerp(
          portfolioPalette[index],
          other.portfolioPalette[index % other.portfolioPalette.length],
          t,
        )!,
        growable: false,
      ),
    );
  }
}

extension FinancialColorsBuildContext on BuildContext {
  FinancialColors get financialColors =>
      Theme.of(this).extension<FinancialColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? FinancialColors.dark
          : FinancialColors.light);
}
