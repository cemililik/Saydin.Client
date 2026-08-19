import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// A metric's provenance state in a share projection.
///
/// [notRequested] and [unavailable] intentionally remain distinct. A missing
/// inflation result must never be presented as zero, and callers can explain
/// whether the metric was outside the calculation request or could not be
/// produced for a request that included it.
enum ShareMetricAvailability { notRequested, unavailable, available }

/// Immutable, typed percentage evidence.
final class SharePercentEvidence extends Equatable {
  final ShareMetricAvailability availability;
  final double? value;

  const SharePercentEvidence.notRequested()
    : availability = ShareMetricAvailability.notRequested,
      value = null;

  const SharePercentEvidence.unavailable()
    : availability = ShareMetricAvailability.unavailable,
      value = null;

  factory SharePercentEvidence.available(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    return SharePercentEvidence._(
      availability: ShareMetricAvailability.available,
      value: value,
    );
  }

  const SharePercentEvidence._({required this.availability, this.value});

  factory SharePercentEvidence.fromNullable(
    double? value, {
    required bool requested,
  }) {
    if (value != null) return SharePercentEvidence.available(value);
    return requested
        ? const SharePercentEvidence.unavailable()
        : const SharePercentEvidence.notRequested();
  }

  bool get isAvailable => availability == ShareMetricAvailability.available;

  @override
  List<Object?> get props => [availability, value];
}

/// Immutable, typed monetary evidence.
///
/// Values remain [Decimal] through the projection boundary. Formatting is a
/// presentation concern and is the only place that may convert to `double`.
final class ShareDecimalEvidence extends Equatable {
  final ShareMetricAvailability availability;
  final Decimal? value;

  const ShareDecimalEvidence.notRequested()
    : availability = ShareMetricAvailability.notRequested,
      value = null;

  const ShareDecimalEvidence.unavailable()
    : availability = ShareMetricAvailability.unavailable,
      value = null;

  const ShareDecimalEvidence.available(Decimal this.value)
    : availability = ShareMetricAvailability.available;

  factory ShareDecimalEvidence.fromNullable(
    Decimal? value, {
    required bool requested,
  }) {
    if (value != null) return ShareDecimalEvidence.available(value);
    return requested
        ? const ShareDecimalEvidence.unavailable()
        : const ShareDecimalEvidence.notRequested();
  }

  bool get isAvailable => availability == ShareMetricAvailability.available;

  @override
  List<Object?> get props => [availability, value];
}

/// How completely an aggregate date is known.
///
/// A portfolio can have successful and failed items. [partial] prevents a
/// date observed on one successful item from being misrepresented as the date
/// of the entire portfolio.
enum ShareDateCoverage { unavailable, partial, complete }

/// One date or a conservative range of dates with explicit coverage.
///
/// A range is produced whenever source snapshots disagree. Projectors never
/// pick an arbitrary first/last item and label it as a single portfolio date.
final class ShareDateValue extends Equatable {
  final ShareDateCoverage coverage;
  final DateTime? earliest;
  final DateTime? latest;

  const ShareDateValue.unavailable()
    : coverage = ShareDateCoverage.unavailable,
      earliest = null,
      latest = null;

  const ShareDateValue.single(DateTime value)
    : coverage = ShareDateCoverage.complete,
      earliest = value,
      latest = value;

  factory ShareDateValue.range(DateTime earliest, DateTime latest) {
    if (latest.isBefore(earliest)) {
      throw ArgumentError.value(
        latest,
        'latest',
        'must not be before earliest',
      );
    }
    return ShareDateValue._(
      coverage: ShareDateCoverage.complete,
      earliest: earliest,
      latest: latest,
    );
  }

  const ShareDateValue._({
    required this.coverage,
    required this.earliest,
    required this.latest,
  });

  /// Aggregates all candidates without hiding missing or mixed evidence.
  ///
  /// Pass one candidate per source item, including `null` for an item whose
  /// date is unavailable. An empty iterable is also unavailable.
  factory ShareDateValue.fromCandidates(Iterable<DateTime?> candidates) {
    final all = candidates.toList(growable: false);
    if (all.isEmpty) return const ShareDateValue.unavailable();

    final available = all.whereType<DateTime>().toList(growable: false);
    if (available.isEmpty) return const ShareDateValue.unavailable();

    var earliest = available.first;
    var latest = available.first;
    for (final value in available.skip(1)) {
      if (value.isBefore(earliest)) earliest = value;
      if (value.isAfter(latest)) latest = value;
    }

    return ShareDateValue._(
      coverage: available.length == all.length
          ? ShareDateCoverage.complete
          : ShareDateCoverage.partial,
      earliest: earliest,
      latest: latest,
    );
  }

  bool get isAvailable => coverage != ShareDateCoverage.unavailable;

  bool get isRange => earliest != latest;

  /// True when either source coverage is incomplete or source dates differ.
  bool get isMixed => coverage == ShareDateCoverage.partial || isRange;

  @override
  List<Object?> get props => [coverage, earliest, latest];
}

/// The meaning of the start/end evidence carried by [ShareDateEvidence].
enum ShareDateContext {
  /// A single buy followed by a sale or valuation.
  trade,

  /// A recurring-purchase window; buy evidence can itself be a range.
  recurringInvestment,

  /// One buy request projected over multiple portfolio items.
  portfolio,
}

/// Requested and effective transaction dates for a share snapshot.
///
/// For recurring investments, buy values describe the requested/effective
/// purchase window and sell values describe the requested/effective valuation
/// end. [context] lets presentation use accurate labels rather than implying a
/// literal sale.
final class ShareDateEvidence extends Equatable {
  final ShareDateContext context;
  final ShareDateValue requestedBuy;
  final ShareDateValue effectiveBuy;
  final ShareDateValue requestedSell;
  final ShareDateValue effectiveSell;
  final ShareDateValue calculatedAt;

  const ShareDateEvidence({
    required this.context,
    required this.requestedBuy,
    required this.effectiveBuy,
    required this.requestedSell,
    required this.effectiveSell,
    this.calculatedAt = const ShareDateValue.unavailable(),
  });

  bool get hasAdjustedBuy => requestedBuy != effectiveBuy;

  bool get hasAdjustedSell => requestedSell != effectiveSell;

  bool get hasMixedEvidence =>
      requestedBuy.isMixed ||
      effectiveBuy.isMixed ||
      requestedSell.isMixed ||
      effectiveSell.isMixed ||
      calculatedAt.isMixed;

  @override
  List<Object?> get props => [
    context,
    requestedBuy,
    effectiveBuy,
    requestedSell,
    effectiveSell,
    calculatedAt,
  ];
}

/// Inflation evidence whose fields retain their availability independently.
final class ShareInflationEvidence extends Equatable {
  final SharePercentEvidence cumulativeInflationPercent;
  final SharePercentEvidence realProfitLossPercent;
  final ShareDecimalEvidence realProfitLossTry;
  final ShareDateValue cpiAsOf;

  const ShareInflationEvidence({
    required this.cumulativeInflationPercent,
    required this.realProfitLossPercent,
    required this.realProfitLossTry,
    this.cpiAsOf = const ShareDateValue.unavailable(),
  });

  factory ShareInflationEvidence.fromNullable({
    required bool requested,
    double? cumulativeInflationPercent,
    double? realProfitLossPercent,
    Decimal? realProfitLossTry,
    Iterable<DateTime?> cpiAsOfCandidates = const <DateTime?>[],
  }) => ShareInflationEvidence(
    cumulativeInflationPercent: SharePercentEvidence.fromNullable(
      cumulativeInflationPercent,
      requested: requested,
    ),
    realProfitLossPercent: SharePercentEvidence.fromNullable(
      realProfitLossPercent,
      requested: requested,
    ),
    realProfitLossTry: ShareDecimalEvidence.fromNullable(
      realProfitLossTry,
      requested: requested,
    ),
    cpiAsOf: ShareDateValue.fromCandidates(cpiAsOfCandidates),
  );

  bool get hasAnyAvailableMetric =>
      cumulativeInflationPercent.isAvailable ||
      realProfitLossPercent.isAvailable ||
      realProfitLossTry.isAvailable;

  @override
  List<Object?> get props => [
    cumulativeInflationPercent,
    realProfitLossPercent,
    realProfitLossTry,
    cpiAsOf,
  ];
}

/// Exact nominal financial outcome shared by all calculation projections.
final class ShareNominalOutcome extends Equatable {
  final Decimal initialValueTry;
  final Decimal finalValueTry;
  final Decimal profitLossTry;
  final double profitLossPercent;

  factory ShareNominalOutcome({
    required Decimal initialValueTry,
    required Decimal finalValueTry,
    required Decimal profitLossTry,
    required double profitLossPercent,
  }) {
    if (!profitLossPercent.isFinite) {
      throw ArgumentError.value(
        profitLossPercent,
        'profitLossPercent',
        'must be finite',
      );
    }
    return ShareNominalOutcome._(
      initialValueTry: initialValueTry,
      finalValueTry: finalValueTry,
      profitLossTry: profitLossTry,
      profitLossPercent: profitLossPercent,
    );
  }

  const ShareNominalOutcome._({
    required this.initialValueTry,
    required this.finalValueTry,
    required this.profitLossTry,
    required this.profitLossPercent,
  });

  @override
  List<Object?> get props => [
    initialValueTry,
    finalValueTry,
    profitLossTry,
    profitLossPercent,
  ];
}
