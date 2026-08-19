import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/share/share_financial_evidence.dart';

void main() {
  group('ShareDateValue', () {
    test('mixed candidates remain a range instead of selecting one date', () {
      final value = ShareDateValue.fromCandidates([
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5),
      ]);

      expect(value.coverage, ShareDateCoverage.complete);
      expect(value.earliest, DateTime(2024, 1, 3));
      expect(value.latest, DateTime(2024, 1, 5));
      expect(value.isRange, isTrue);
      expect(value.isMixed, isTrue);
    });

    test('missing aggregate member remains explicit partial evidence', () {
      final value = ShareDateValue.fromCandidates([DateTime(2024, 1, 3), null]);

      expect(value.coverage, ShareDateCoverage.partial);
      expect(value.earliest, DateTime(2024, 1, 3));
      expect(value.latest, DateTime(2024, 1, 3));
      expect(value.isMixed, isTrue);
    });
  });

  group('typed metric evidence', () {
    test('requested missing metric is unavailable, never numeric zero', () {
      final metric = SharePercentEvidence.fromNullable(null, requested: true);

      expect(metric.availability, ShareMetricAvailability.unavailable);
      expect(metric.value, isNull);
    });

    test('present evidence is preserved even when request flag is false', () {
      final metric = ShareDecimalEvidence.fromNullable(
        Decimal.parse('12.34'),
        requested: false,
      );

      expect(metric.availability, ShareMetricAvailability.available);
      expect(metric.value, Decimal.parse('12.34'));
    });

    test('non-finite percentage cannot enter projection contract', () {
      expect(
        () => SharePercentEvidence.available(double.infinity),
        throwsArgumentError,
      );
    });
  });
}
