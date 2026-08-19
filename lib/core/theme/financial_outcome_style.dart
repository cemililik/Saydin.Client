import 'package:flutter/material.dart';
import 'package:saydin/core/theme/financial_colors.dart';
import 'package:saydin/core/utils/financial_outcome.dart';
import 'package:saydin/l10n/app_localizations.dart';

/// Üç durumlu finansal anlamın kullanıcıya görünen tek sunum sözleşmesi.
extension FinancialOutcomeStyle on FinancialOutcome {
  Color color(BuildContext context) => switch (this) {
    FinancialOutcome.profit => context.financialColors.profit,
    FinancialOutcome.neutral => context.financialColors.neutral,
    FinancialOutcome.loss => context.financialColors.loss,
  };

  Color get shareColor => switch (this) {
    FinancialOutcome.profit => const Color(0xFF2E7D32),
    FinancialOutcome.neutral => const Color(0xFF455A64),
    FinancialOutcome.loss => const Color(0xFFC62828),
  };

  IconData get icon => switch (this) {
    FinancialOutcome.profit => Icons.trending_up,
    FinancialOutcome.neutral => Icons.trending_flat,
    FinancialOutcome.loss => Icons.trending_down,
  };

  String title(AppLocalizations l10n) => switch (this) {
    FinancialOutcome.profit => l10n.profit,
    FinancialOutcome.neutral => l10n.noChange,
    FinancialOutcome.loss => l10n.loss,
  };

  String amountLabel(AppLocalizations l10n) => switch (this) {
    FinancialOutcome.profit => l10n.profitLabel,
    FinancialOutcome.neutral => l10n.changeLabel,
    FinancialOutcome.loss => l10n.lossLabel,
  };

  String shareLabel(AppLocalizations l10n) => switch (this) {
    FinancialOutcome.profit => l10n.shareCardProfit,
    FinancialOutcome.neutral => l10n.shareCardNeutral,
    FinancialOutcome.loss => l10n.shareCardLoss,
  };

  String get explicitPositiveSign => switch (this) {
    FinancialOutcome.profit => '+',
    FinancialOutcome.neutral || FinancialOutcome.loss => '',
  };
}
