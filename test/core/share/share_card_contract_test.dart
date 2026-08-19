import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/share/share_card_contract.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';
import 'package:saydin/features/comparison/domain/entities/comparison_share_projection.dart';
import 'package:saydin/features/dca/domain/entities/dca_share_projection.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_share_projection.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_share_projection.dart';

void main() {
  group('ShareDraft and SharePayload typing', () {
    test('derives exactly one variant from each of the five projections', () {
      final whatIf = _draft(_whatIfProjection()).toPayload();
      final reverse = _draft(_reverseProjection()).toPayload();
      final comparison = _draft(_comparisonProjection()).toPayload();
      final portfolio = _portfolioDraft(_portfolioProjection()).toPayload();
      final dca = _draft(_dcaProjection()).toPayload();

      final SharePayload<WhatIfShareProjection> typedWhatIf = whatIf;
      final SharePayload<ReverseWhatIfShareProjection> typedReverse = reverse;
      final SharePayload<ComparisonShareProjection> typedComparison =
          comparison;
      final SharePayload<PortfolioShareProjection> typedPortfolio = portfolio;
      final SharePayload<DcaShareProjection> typedDca = dca;

      expect(typedWhatIf.variant, ShareCardVariant.whatIf);
      expect(typedReverse.variant, ShareCardVariant.reverseWhatIf);
      expect(typedComparison.variant, ShareCardVariant.comparison);
      expect(typedPortfolio.variant, ShareCardVariant.portfolio);
      expect(typedDca.variant, ShareCardVariant.dca);
      expect({
        typedWhatIf.variant,
        typedReverse.variant,
        typedComparison.variant,
        typedPortfolio.variant,
        typedDca.variant,
      }, hasLength(5));
    });

    test('rejects portfolio distribution privacy on a non-portfolio card', () {
      expect(
        () => ShareDraft(
          projection: _whatIfProjection(),
          caption: _caption(),
          privacy: const SharePrivacyOptions.portfolio(),
          accessibleSummary: 'Accessible summary',
        ),
        throwsArgumentError,
      );
      expect(
        () => _draft(_whatIfProjection()).withShowDistribution(
          false,
          localizedDefaultCaptionBody: 'No distribution default',
          accessibleSummary: 'No distribution summary',
        ),
        throwsStateError,
      );
    });

    test('requires distribution privacy on a portfolio card', () {
      expect(
        () => ShareDraft(
          projection: _portfolioProjection(),
          caption: _caption(),
          privacy: const SharePrivacyOptions.standard(),
          accessibleSummary: 'Accessible summary',
        ),
        throwsArgumentError,
      );
    });
  });

  group('caption editing', () {
    test(
      'edit survives privacy and CTA toggles and reset is deterministic',
      () {
        final initial = _draft(_whatIfProjection());
        final edited = initial
            .editCaptionBody('User-edited body')
            .withShowAmounts(
              false,
              localizedDefaultCaptionBody: 'Privacy-safe default body',
              accessibleSummary: 'Summary without amounts',
            )
            .withCtaEnabled(false)
            .withCtaEnabled(true);

        expect(edited.caption.body, 'User-edited body');
        expect(
          edited.caption.localizedDefaultBody,
          'Privacy-safe default body',
        );
        expect(edited.privacy.showAmounts, isFalse);
        expect(edited.accessibleSummary, 'Summary without amounts');
        expect(
          edited.toPayload().finalCaption,
          'User-edited body\n\nLocalized CTA',
        );

        final resetOnce = edited.resetCaptionBody();
        final resetTwice = resetOnce.resetCaptionBody();
        expect(resetOnce.caption.body, 'Privacy-safe default body');
        expect(resetTwice, resetOnce);
        expect(resetOnce.privacy, edited.privacy);
        expect(resetOnce.caption.isCtaEnabled, edited.caption.isCtaEnabled);
      },
    );

    test('edit survives both portfolio privacy toggles', () {
      final edited = _portfolioDraft(_portfolioProjection())
          .editCaptionBody('User-edited portfolio body')
          .withShowAmounts(
            false,
            localizedDefaultCaptionBody: 'Portfolio without amounts',
            accessibleSummary: 'Portfolio summary without amounts',
          )
          .withShowDistribution(
            false,
            localizedDefaultCaptionBody:
                'Portfolio without amounts or distribution',
            accessibleSummary:
                'Portfolio summary without amounts or distribution',
          );

      expect(edited.caption.body, 'User-edited portfolio body');
      expect(edited.privacy.showAmounts, isFalse);
      expect(edited.privacy.showDistribution, isFalse);
      expect(
        edited.accessibleSummary,
        'Portfolio summary without amounts or distribution',
      );
      expect(
        edited.accessibleSummary,
        isNot('Portfolio summary without amounts'),
      );
      expect(
        edited.caption.localizedDefaultBody,
        'Portfolio without amounts or distribution',
      );
      expect(
        edited.toPayload().finalCaption,
        'User-edited portfolio body\n\nLocalized CTA',
      );
    });

    test('privacy toggle replaces an untouched body and stale summary', () {
      final hidden = _draft(_whatIfProjection()).withShowAmounts(
        false,
        localizedDefaultCaptionBody: 'Default without amounts',
        accessibleSummary: 'Summary without amounts',
      );

      expect(hidden.caption.isBodyEdited, isFalse);
      expect(hidden.caption.body, 'Default without amounts');
      expect(hidden.caption.localizedDefaultBody, 'Default without amounts');
      expect(hidden.accessibleSummary, 'Summary without amounts');
      expect(hidden.accessibleSummary, isNot('Accessible summary'));
    });

    test(
      'edited body survives privacy toggle but its reset target changes',
      () {
        final hidden = _draft(_whatIfProjection())
            .editCaptionBody('Explicit user edit')
            .withShowAmounts(
              false,
              localizedDefaultCaptionBody: 'Default without amounts',
              accessibleSummary: 'Summary without amounts',
            );

        expect(hidden.caption.isBodyEdited, isTrue);
        expect(hidden.caption.body, 'Explicit user edit');
        expect(
          hidden.resetCaptionBody().caption.body,
          'Default without amounts',
        );
        expect(hidden.resetCaptionBody().caption.isBodyEdited, isFalse);
      },
    );

    test('CTA toggle changes only the optional CTA segment', () {
      final enabled = _draft(_whatIfProjection()).toPayload();
      final disabled = _draft(
        _whatIfProjection(),
      ).withCtaEnabled(false).toPayload();

      expect(enabled.caption.body, disabled.caption.body);
      expect(enabled.projection, disabled.projection);
      expect(enabled.privacy, disabled.privacy);
      expect(enabled.accessibleSummary, disabled.accessibleSummary);
      expect(enabled.caption.ctaSegment, 'Localized CTA');
      expect(disabled.caption.ctaSegment, isNull);
      expect(enabled.finalCaption, 'Localized default body\n\nLocalized CTA');
      expect(disabled.finalCaption, 'Localized default body');
    });

    test('cannot enable a CTA when the caller did not provide one', () {
      final caption = ShareCaptionDraft(
        localizedDefaultBody: 'Localized default body',
      );

      expect(() => caption.withCtaEnabled(true), throwsArgumentError);
    });

    test('legacy CTA line breaks do not create a double separator', () {
      final caption = ShareCaptionDraft(
        localizedDefaultBody: 'Localized default body',
        ctaSegment: '\n\nLocalized CTA',
        isCtaEnabled: true,
      ).toCaption();

      expect(caption.finalCaption, 'Localized default body\n\nLocalized CTA');
    });
  });

  group('payload metadata and accessibility', () {
    test('canonical preset is 1080x1350 from a 540x675 logical frame', () {
      final preset = _draft(_dcaProjection()).toPayload().preset;

      expect(preset.rasterWidthPixels, 1080);
      expect(preset.rasterHeightPixels, 1350);
      expect(preset.logicalWidth, 540);
      expect(preset.logicalHeight, 675);
      expect(preset.pixelRatio, 2);
    });

    test('requires a non-empty caller-provided accessible summary', () {
      expect(
        () => ShareDraft(
          projection: _dcaProjection(),
          caption: _caption(),
          privacy: const SharePrivacyOptions.standard(),
          accessibleSummary: '  ',
        ),
        throwsArgumentError,
      );
    });

    test('payloads have value equality without telemetry state', () {
      final first = _draft(_dcaProjection()).toPayload();
      final second = _draft(_dcaProjection()).toPayload();

      expect(first, second);
    });
  });
}

ShareDraft<P> _draft<P extends ShareCardProjection>(P projection) =>
    ShareDraft<P>(
      projection: projection,
      caption: _caption(),
      privacy: const SharePrivacyOptions.standard(),
      accessibleSummary: 'Accessible summary',
    );

ShareDraft<PortfolioShareProjection> _portfolioDraft(
  PortfolioShareProjection projection,
) => ShareDraft<PortfolioShareProjection>(
  projection: projection,
  caption: _caption(),
  privacy: const SharePrivacyOptions.portfolio(),
  accessibleSummary: 'Accessible summary',
);

ShareCaptionDraft _caption() => ShareCaptionDraft(
  localizedDefaultBody: 'Localized default body',
  ctaSegment: 'Localized CTA',
  isCtaEnabled: true,
);

WhatIfShareProjection _whatIfProjection() => WhatIfShareProjection(
  assetSymbol: 'XAU',
  assetDisplayName: 'Asset',
  nominalOutcome: _outcome(),
  dates: _dates(),
  inflation: _inflation(),
);

ReverseWhatIfShareProjection _reverseProjection() =>
    ReverseWhatIfShareProjection(
      assetSymbol: 'XAU',
      assetDisplayName: 'Asset',
      nominalOutcome: _outcome(),
      dates: _dates(),
      inflation: _inflation(),
    );

ComparisonShareProjection _comparisonProjection() => ComparisonShareProjection(
  returnMode: ComparisonShareReturnMode.nominal,
  rankingBasis: ComparisonShareRankingBasis.nominalProfitLossPercent,
  items: const [],
  dates: _dates(),
  cpiAsOf: const ShareDateValue.unavailable(),
);

PortfolioShareProjection _portfolioProjection() => PortfolioShareProjection(
  items: const [],
  failureCount: 0,
  nominalOutcome: _outcome(),
  dates: _dates(),
  inflation: _inflation(),
);

DcaShareProjection _dcaProjection() => DcaShareProjection(
  assetSymbol: 'XAU',
  assetDisplayName: 'Asset',
  period: 'monthly',
  periodicAmount: Decimal.fromInt(100),
  totalPurchases: 12,
  nominalOutcome: _outcome(),
  dates: _dates(context: ShareDateContext.recurringInvestment),
  inflation: _inflation(),
);

ShareNominalOutcome _outcome() => ShareNominalOutcome(
  initialValueTry: Decimal.fromInt(100),
  finalValueTry: Decimal.fromInt(120),
  profitLossTry: Decimal.fromInt(20),
  profitLossPercent: 20,
);

ShareDateEvidence _dates({ShareDateContext context = ShareDateContext.trade}) =>
    ShareDateEvidence(
      context: context,
      requestedBuy: const ShareDateValue.unavailable(),
      effectiveBuy: const ShareDateValue.unavailable(),
      requestedSell: const ShareDateValue.unavailable(),
      effectiveSell: const ShareDateValue.unavailable(),
    );

ShareInflationEvidence _inflation() => const ShareInflationEvidence(
  cumulativeInflationPercent: SharePercentEvidence.notRequested(),
  realProfitLossPercent: SharePercentEvidence.notRequested(),
  realProfitLossTry: ShareDecimalEvidence.notRequested(),
);
