import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/theme/app_theme.dart';
import 'package:saydin/core/theme/financial_colors.dart';

void main() {
  double contrastRatio(Color foreground, Color background) {
    final light = foreground.computeLuminance() > background.computeLuminance()
        ? foreground.computeLuminance()
        : background.computeLuminance();
    final dark = foreground.computeLuminance() > background.computeLuminance()
        ? background.computeLuminance()
        : foreground.computeLuminance();
    return (light + 0.05) / (dark + 0.05);
  }

  for (final entry in <String, ThemeData>{
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  }.entries) {
    test(
      '${entry.key} tema finansal renkleri yüzey üzerinde AA kontrast sağlar',
      () {
        final theme = entry.value;
        final colors = theme.extension<FinancialColors>();

        expect(colors, isNotNull);
        expect(
          contrastRatio(colors!.profit, theme.colorScheme.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(colors.loss, theme.colorScheme.surface),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
  }

  test('bottom navigation açık/koyu temada semantic surface kullanır', () {
    expect(
      AppTheme.light.bottomNavigationBarTheme.backgroundColor,
      AppTheme.light.colorScheme.surfaceContainer,
    );
    expect(
      AppTheme.dark.bottomNavigationBarTheme.backgroundColor,
      AppTheme.dark.colorScheme.surfaceContainer,
    );
  });
}
