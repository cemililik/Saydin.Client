import 'package:decimal/decimal.dart';

/// Finansal sonucun üç durumlu anlamı.
///
/// Backend'in eski `isProfit` boolean alanı sıfır değişimi temsil edemez.
/// Kullanıcıya gösterilen renk, ikon ve metin bu exact değerden türetilir;
/// böylece sıfır getiri ne kâr ne de zarar gibi sunulur.
enum FinancialOutcome {
  profit,
  neutral,
  loss;

  factory FinancialOutcome.fromAmount(Decimal value) {
    if (value > Decimal.zero) return FinancialOutcome.profit;
    if (value < Decimal.zero) return FinancialOutcome.loss;
    return FinancialOutcome.neutral;
  }

  factory FinancialOutcome.fromPercent(num value) {
    if (value > 0) return FinancialOutcome.profit;
    if (value < 0) return FinancialOutcome.loss;
    return FinancialOutcome.neutral;
  }

  bool get isProfit => this == FinancialOutcome.profit;
}
