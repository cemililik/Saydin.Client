import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/l10n/app_localizations_en.dart';
import 'package:saydin/l10n/app_localizations_tr.dart';

void main() {
  test(
    'chart accessibility and portfolio summary keys preserve placeholders',
    () {
      final tr = AppLocalizationsTr();
      final en = AppLocalizationsEn();

      expect(tr.chartDataShow, isNotEmpty);
      expect(en.chartDataHide, isNotEmpty);
      expect(tr.priceChartSummary('A', 'B', 'C', 'D', 'E'), contains('A'));
      expect(en.dcaChartSummary('A', 'B', 'C', 'D'), contains('D'));
      expect(tr.chartDataPoint('A', 'B'), contains('B'));
      expect(en.dcaChartDataPoint('A', 'B', 'C'), contains('C'));
      expect(tr.shareCardMoreAssets(14), contains('14'));
      expect(en.shareCardMoreAssets(1), contains('1'));
    },
  );
}
