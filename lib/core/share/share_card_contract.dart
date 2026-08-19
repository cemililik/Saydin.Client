import 'package:equatable/equatable.dart';

/// The five share-card experiences supported by the application.
///
/// A payload never accepts this value separately. It is derived from the
/// typed [ShareCardProjection], so callers cannot pair a projection with a
/// different card variant by mistake.
enum ShareCardVariant { whatIf, reverseWhatIf, comparison, portfolio, dca }

/// Pure-Dart contract implemented by every share-ready projection.
abstract interface class ShareCardProjection {
  ShareCardVariant get shareCardVariant;
}

/// Immutable metadata for the canonical exported share-card artboard.
///
/// Logical dimensions keep widget layout independent from raster density.
/// Rendering at [pixelRatio] produces the exact raster dimensions.
final class ShareCardPreset extends Equatable {
  static const canonicalPortrait = ShareCardPreset._(
    rasterWidthPixels: 1080,
    rasterHeightPixels: 1350,
    logicalWidth: 540,
    logicalHeight: 675,
  );

  final int rasterWidthPixels;
  final int rasterHeightPixels;
  final int logicalWidth;
  final int logicalHeight;

  const ShareCardPreset._({
    required this.rasterWidthPixels,
    required this.rasterHeightPixels,
    required this.logicalWidth,
    required this.logicalHeight,
  });

  double get pixelRatio => rasterWidthPixels / logicalWidth;

  @override
  List<Object?> get props => [
    rasterWidthPixels,
    rasterHeightPixels,
    logicalWidth,
    logicalHeight,
  ];
}

/// Privacy controls carried with a draft and its final payload.
///
/// [showDistribution] is deliberately nullable: `null` means that the card
/// variant does not support a distribution control. Portfolio drafts require
/// a non-null value, while every other variant rejects one.
final class SharePrivacyOptions extends Equatable {
  final bool showAmounts;
  final bool? showDistribution;

  const SharePrivacyOptions.standard({this.showAmounts = true})
    : showDistribution = null;

  const SharePrivacyOptions.portfolio({
    this.showAmounts = true,
    this.showDistribution = true,
  });

  bool get supportsDistribution => showDistribution != null;

  SharePrivacyOptions withShowAmounts(bool value) => SharePrivacyOptions._(
    showAmounts: value,
    showDistribution: showDistribution,
  );

  SharePrivacyOptions withShowDistribution(bool value) {
    if (!supportsDistribution) {
      throw StateError(
        'Distribution visibility is only available for portfolio cards.',
      );
    }
    return SharePrivacyOptions._(
      showAmounts: showAmounts,
      showDistribution: value,
    );
  }

  const SharePrivacyOptions._({
    required this.showAmounts,
    required this.showDistribution,
  });

  @override
  List<Object?> get props => [showAmounts, showDistribution];
}

/// Editable caption state whose localized default is supplied by the caller.
///
/// The contract does not import localization code and does not invent copy.
/// It only keeps the caller's default, current body and optional CTA segment
/// separate so changing one concern cannot silently overwrite another.
final class ShareCaptionDraft extends Equatable {
  final String localizedDefaultBody;
  final String body;
  final String? ctaSegment;
  final bool isCtaEnabled;
  final bool isBodyEdited;

  factory ShareCaptionDraft({
    required String localizedDefaultBody,
    String? body,
    String? ctaSegment,
    bool isCtaEnabled = false,
  }) {
    _validateCta(ctaSegment, isCtaEnabled);
    return ShareCaptionDraft._(
      localizedDefaultBody: localizedDefaultBody,
      body: body ?? localizedDefaultBody,
      ctaSegment: ctaSegment,
      isCtaEnabled: isCtaEnabled,
      isBodyEdited: body != null,
    );
  }

  const ShareCaptionDraft._({
    required this.localizedDefaultBody,
    required this.body,
    required this.ctaSegment,
    required this.isCtaEnabled,
    required this.isBodyEdited,
  });

  ShareCaptionDraft editBody(String value) =>
      _copyWith(body: value, isBodyEdited: true);

  ShareCaptionDraft resetBody() =>
      _copyWith(body: localizedDefaultBody, isBodyEdited: false);

  /// Replaces the caller's localized default after a privacy change.
  ///
  /// An explicitly edited body is preserved. An untouched body follows the
  /// regenerated privacy-safe default, and reset always targets that latest
  /// default.
  ShareCaptionDraft withLocalizedDefaultBody(String value) =>
      ShareCaptionDraft._(
        localizedDefaultBody: value,
        body: isBodyEdited ? body : value,
        ctaSegment: ctaSegment,
        isCtaEnabled: isCtaEnabled,
        isBodyEdited: isBodyEdited,
      );

  ShareCaptionDraft withCtaEnabled(bool value) {
    _validateCta(ctaSegment, value);
    return _copyWith(isCtaEnabled: value);
  }

  ShareCaption toCaption() =>
      ShareCaption(body: body, ctaSegment: isCtaEnabled ? ctaSegment : null);

  ShareCaptionDraft _copyWith({
    String? body,
    bool? isCtaEnabled,
    bool? isBodyEdited,
  }) => ShareCaptionDraft._(
    localizedDefaultBody: localizedDefaultBody,
    body: body ?? this.body,
    ctaSegment: ctaSegment,
    isCtaEnabled: isCtaEnabled ?? this.isCtaEnabled,
    isBodyEdited: isBodyEdited ?? this.isBodyEdited,
  );

  static void _validateCta(String? segment, bool enabled) {
    if (segment != null && segment.trim().isEmpty) {
      throw ArgumentError.value(
        segment,
        'ctaSegment',
        'must contain visible text when supplied',
      );
    }
    if (enabled && segment == null) {
      throw ArgumentError(
        'CTA cannot be enabled without a caller-provided CTA segment.',
      );
    }
  }

  @override
  List<Object?> get props => [
    localizedDefaultBody,
    body,
    ctaSegment,
    isCtaEnabled,
    isBodyEdited,
  ];
}

/// Caption snapshot included in a render-ready payload.
final class ShareCaption extends Equatable {
  static const _segmentSeparator = '\n\n';

  final String body;
  final String? ctaSegment;

  const ShareCaption({required this.body, this.ctaSegment});

  /// The exact text supplied to the platform share sheet.
  String get finalCaption {
    final cta = ctaSegment;
    if (cta == null) return body;
    // Existing localized CTA values already start with line breaks. Treat
    // those as legacy separators so migration cannot double-space segments.
    final ctaBody = cta.replaceFirst(RegExp(r'^(?:\r\n|\r|\n)+'), '');
    if (body.isEmpty) return ctaBody;
    return '$body$_segmentSeparator$ctaBody';
  }

  @override
  List<Object?> get props => [body, ctaSegment];
}

/// Immutable editor state used before a render/share action.
final class ShareDraft<P extends ShareCardProjection> extends Equatable {
  final P projection;
  final ShareCaptionDraft caption;
  final SharePrivacyOptions privacy;
  final String accessibleSummary;
  final ShareCardPreset preset;

  factory ShareDraft({
    required P projection,
    required ShareCaptionDraft caption,
    required SharePrivacyOptions privacy,
    required String accessibleSummary,
    ShareCardPreset preset = ShareCardPreset.canonicalPortrait,
  }) {
    _validate(projection, privacy, accessibleSummary);
    return ShareDraft<P>._(
      projection: projection,
      caption: caption,
      privacy: privacy,
      accessibleSummary: accessibleSummary,
      preset: preset,
    );
  }

  const ShareDraft._({
    required this.projection,
    required this.caption,
    required this.privacy,
    required this.accessibleSummary,
    required this.preset,
  });

  ShareCardVariant get variant => projection.shareCardVariant;

  ShareDraft<P> editCaptionBody(String value) =>
      _copyWith(caption: caption.editBody(value));

  ShareDraft<P> resetCaptionBody() => _copyWith(caption: caption.resetBody());

  ShareDraft<P> withCtaEnabled(bool value) =>
      _copyWith(caption: caption.withCtaEnabled(value));

  /// Changes amount visibility with regenerated privacy-safe caller copy.
  ShareDraft<P> withShowAmounts(
    bool value, {
    required String localizedDefaultCaptionBody,
    required String accessibleSummary,
  }) => _copyWith(
    caption: caption.withLocalizedDefaultBody(localizedDefaultCaptionBody),
    privacy: privacy.withShowAmounts(value),
    accessibleSummary: accessibleSummary,
  );

  /// Changes portfolio distribution visibility with regenerated caller copy.
  ShareDraft<P> withShowDistribution(
    bool value, {
    required String localizedDefaultCaptionBody,
    required String accessibleSummary,
  }) {
    if (variant != ShareCardVariant.portfolio) {
      throw StateError(
        'Distribution visibility is only available for portfolio cards.',
      );
    }
    return _copyWith(
      caption: caption.withLocalizedDefaultBody(localizedDefaultCaptionBody),
      privacy: privacy.withShowDistribution(value),
      accessibleSummary: accessibleSummary,
    );
  }

  ShareDraft<P> withAccessibleSummary(String value) =>
      _copyWith(accessibleSummary: value);

  SharePayload<P> toPayload() => SharePayload<P>._(
    projection: projection,
    caption: caption.toCaption(),
    privacy: privacy,
    accessibleSummary: accessibleSummary,
    preset: preset,
  );

  ShareDraft<P> _copyWith({
    ShareCaptionDraft? caption,
    SharePrivacyOptions? privacy,
    String? accessibleSummary,
  }) {
    final next = ShareDraft<P>._(
      projection: projection,
      caption: caption ?? this.caption,
      privacy: privacy ?? this.privacy,
      accessibleSummary: accessibleSummary ?? this.accessibleSummary,
      preset: preset,
    );
    _validate(next.projection, next.privacy, next.accessibleSummary);
    return next;
  }

  static void _validate(
    ShareCardProjection projection,
    SharePrivacyOptions privacy,
    String accessibleSummary,
  ) {
    if (accessibleSummary.trim().isEmpty) {
      throw ArgumentError.value(
        accessibleSummary,
        'accessibleSummary',
        'must contain visible text',
      );
    }

    final isPortfolio =
        projection.shareCardVariant == ShareCardVariant.portfolio;
    if (isPortfolio != privacy.supportsDistribution) {
      throw ArgumentError.value(
        privacy,
        'privacy',
        isPortfolio
            ? 'Portfolio cards require a distribution visibility option.'
            : 'Distribution visibility is only valid for portfolio cards.',
      );
    }
  }

  @override
  List<Object?> get props => [
    projection,
    caption,
    privacy,
    accessibleSummary,
    preset,
  ];
}

/// Validated, immutable snapshot consumed by rendering and sharing adapters.
final class SharePayload<P extends ShareCardProjection> extends Equatable {
  final P projection;
  final ShareCaption caption;
  final SharePrivacyOptions privacy;
  final String accessibleSummary;
  final ShareCardPreset preset;

  const SharePayload._({
    required this.projection,
    required this.caption,
    required this.privacy,
    required this.accessibleSummary,
    required this.preset,
  });

  ShareCardVariant get variant => projection.shareCardVariant;

  String get finalCaption => caption.finalCaption;

  @override
  List<Object?> get props => [
    projection,
    caption,
    privacy,
    accessibleSummary,
    preset,
  ];
}
