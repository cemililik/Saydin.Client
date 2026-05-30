import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/error/app_error.dart';
import 'package:saydin/core/error/app_error_messages.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:saydin/l10n/app_localizations_en.dart';
import 'package:saydin/l10n/app_localizations_tr.dart';

void main() {
  final tr = AppLocalizationsTr();
  final en = AppLocalizationsEn();

  group('AppErrorL10n.localizedMessage', () {
    test('non-feature variants resolve to their own keys (TR)', () {
      expect(
        const PriceNotFoundError().localizedMessage(tr),
        tr.errorPriceNotFound,
      );
      expect(const ServerError().localizedMessage(tr), tr.errorServer);
      expect(const UnknownError().localizedMessage(tr), tr.errorGeneric);
      expect(
        const MalformedResponseError().localizedMessage(tr),
        tr.errorMalformed,
      );
    });

    group('FeatureDisabledError picks the per-feature message', () {
      for (final (key, AppLocalizations l10n, String Function() expected) in [
        ('extended_history', tr, () => tr.errorFeatureDisabledExtendedHistory),
        ('inflation', tr, () => tr.errorFeatureDisabledInflation),
        ('comparison', tr, () => tr.errorFeatureDisabledComparison),
        ('dca', tr, () => tr.errorFeatureDisabledDca),
        ('extended_history', en, () => en.errorFeatureDisabledExtendedHistory),
        ('inflation', en, () => en.errorFeatureDisabledInflation),
        ('comparison', en, () => en.errorFeatureDisabledComparison),
        ('dca', en, () => en.errorFeatureDisabledDca),
      ]) {
        test('featureKey "$key" → specific message', () {
          expect(
            FeatureDisabledError(featureKey: key).localizedMessage(l10n),
            expected(),
          );
        });
      }
    });

    test('unknown featureKey falls back to the generic feature message', () {
      expect(
        const FeatureDisabledError(
          featureKey: 'something_new',
        ).localizedMessage(tr),
        tr.errorFeatureDisabled,
      );
    });

    test('null featureKey falls back to the generic feature message', () {
      expect(
        const FeatureDisabledError().localizedMessage(en),
        en.errorFeatureDisabled,
      );
    });
  });
}
