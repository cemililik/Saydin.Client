import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saydin/core/constants/app_branding.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/share_card_renderer.dart';

typedef ShareCardAction =
    Future<ShareDeliveryResult> Function(
      GlobalKey repaintKey, {
      required String caption,
      required Rect viewport,
      required Rect sharePositionOrigin,
      required ShareAuthorization canExecuteShare,
    });

typedef ShareAuthorization = bool Function();
typedef ShareResultListener = void Function(ShareDeliveryResult result);
typedef ShareCaptionCopyAction = Future<void> Function(String caption);
typedef ShareErrorReportAction =
    Future<void> Function(
      Object error,
      StackTrace stackTrace, {
      required String context,
    });

/// Herhangi bir paylaşım kartı widget'ı için önizleme sayfası.
/// WhatIf, Karşılaştırma ve Portföy ekranları bu widget'ı paylaşır.
class SharePreviewSheet extends StatefulWidget {
  final Widget cardWidget;

  /// Native hedefe byte-for-byte iletilecek tamamlanmış caption.
  ///
  /// Yeni çağrılar bunu kullanmalıdır. Geçiş sürecindeki [shareText] çağrıları
  /// preview katmanında mevcut varsayılan metin + CTA sözleşmesine çevrilir.
  final String? caption;

  /// CTA eklenmemiş eski paylaşım metni. [caption] ile birlikte verilemez.
  final String? shareText;
  final ShareCardAction? shareAction;
  final ShareAuthorization canExecuteShare;
  final ShareResultListener? onShareResult;
  final ShareCaptionCopyAction? copyAction;
  final ShareErrorReportAction? errorReportAction;
  final Future<void>? brandAssetReady;

  const SharePreviewSheet({
    super.key,
    required this.cardWidget,
    required this.canExecuteShare,
    this.caption,
    this.shareText,
    @visibleForTesting this.shareAction,
    this.onShareResult,
    @visibleForTesting this.copyAction,
    @visibleForTesting this.errorReportAction,
    @visibleForTesting this.brandAssetReady,
  }) : assert(caption == null || shareText == null);

  @override
  State<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<SharePreviewSheet> {
  final _repaintKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  final _closeFocusNode = FocusNode(debugLabel: 'share-preview-close');
  final _captionFocusNode = FocusNode(debugLabel: 'share-preview-caption');
  final _copyFocusNode = FocusNode(debugLabel: 'share-preview-copy');
  final _shareFocusNode = FocusNode(debugLabel: 'share-preview-share');

  String? _caption;
  String? _statusMessage;
  bool _statusIsError = false;
  bool _isSharing = false;
  bool _sessionActive = true;
  int _shareGeneration = 0;
  Future<void>? _brandAssetReady;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _closeFocusNode.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kartın zorunlu marka lockup'ını önizleme açılır açılmaz decode et.
    // Kullanıcı çok hızlı paylaşsa bile RepaintBoundary yarı yüklenmiş,
    // logosuz bir frame yakalayamaz.
    _brandAssetReady ??=
        widget.brandAssetReady ??
        precacheImage(
          const AssetImage(AppBranding.horizontalLogoOnLightAsset),
          context,
        );
    // Caption preview oturumu boyunca sabittir. Locale/dependency rebuild'i
    // ekranda gösterilen, panoya kopyalanan ve native hedefe teslim edilen
    // revizyonu birbirinden ayıramaz.
    _caption ??= switch (widget.caption) {
      final caption? => caption,
      null =>
        '${widget.shareText ?? context.l10n.shareDefaultText}'
            '${context.l10n.shareCta}',
    };
  }

  @override
  void dispose() {
    // Render/encode sürerken route kapanırsa renderer'ın native gateway
    // öncesindeki canlı yetki kontrolü bu oturum için kesin olarak false olur.
    _invalidateSession();
    _closeFocusNode.dispose();
    _captionFocusNode.dispose();
    _copyFocusNode.dispose();
    _shareFocusNode.dispose();
    super.dispose();
  }

  void _invalidateSession() {
    _sessionActive = false;
    _shareGeneration++;
  }

  bool _isCurrentShare(int generation) =>
      mounted && _sessionActive && generation == _shareGeneration;

  Future<void> _share() async {
    if (_isSharing) return;
    // Preview açıkken remote config değişmiş olabilir. Render/file/native
    // zincirine girmeden çağrı-anı yetkisini yeniden doğrula.
    if (!widget.canExecuteShare()) {
      widget.onShareResult?.call(ShareDeliveryResult.denied);
      return;
    }

    final generation = ++_shareGeneration;
    final shareErrorMessage = context.l10n.shareError;
    setState(() {
      _isSharing = true;
      _statusMessage = context.l10n.sharingInProgress;
      _statusIsError = false;
    });

    // Widget yetkisine ek olarak preview route'unun halen yaşayan aynı
    // paylaşım denemesine ait olduğunu doğrular. Renderer bu callback'i native
    // gateway'den hemen önce yeniden çağırır.
    bool canExecuteCurrentShare() =>
        _sessionActive &&
        generation == _shareGeneration &&
        widget.canExecuteShare();

    try {
      await _brandAssetReady;
      if (!mounted || !_isCurrentShare(generation)) return;

      final viewport = Offset.zero & MediaQuery.sizeOf(context);
      final sharePositionOrigin = ShareCardRenderer.sharePositionOriginFromKey(
        _shareButtonKey,
        viewport: viewport,
      );
      final result =
          await (widget.shareAction ?? ShareCardRenderer.shareFromKey)(
            _repaintKey,
            caption: _caption!,
            viewport: viewport,
            sharePositionOrigin: sharePositionOrigin,
            canExecuteShare: canExecuteCurrentShare,
          );
      if (!_isCurrentShare(generation)) return;
      _handleShareResult(result);
      widget.onShareResult?.call(result);
    } on ShareCardException catch (error, stackTrace) {
      if (!_isCurrentShare(generation)) return;
      _showFailure(shareErrorMessage);
      _reportErrorAfterFeedback(
        error,
        stackTrace,
        reportContext: 'share_card_render',
      );
    } catch (_, stackTrace) {
      if (!_isCurrentShare(generation)) return;
      _showFailure(shareErrorMessage);
      _reportErrorAfterFeedback(
        const _SharePreviewOperationException('share_failed'),
        stackTrace,
        reportContext: 'share_card',
      );
    } finally {
      if (_isCurrentShare(generation)) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _handleShareResult(ShareDeliveryResult result) {
    switch (result) {
      case ShareDeliveryResult.completed:
      case ShareDeliveryResult.dismissed:
      case ShareDeliveryResult.denied:
        // Dismissed ve denied bir başarı ya da hata değildir. Eski busy
        // mesajını temizlemek dışında yanıltıcı geri bildirim üretme.
        setState(() {
          _statusMessage = null;
          _statusIsError = false;
        });
      case ShareDeliveryResult.unavailable:
        setState(() {
          _statusMessage = context.l10n.shareUnavailable;
          _statusIsError = false;
        });
    }
  }

  Future<void> _copyCaption() async {
    try {
      await (widget.copyAction ?? _copyToClipboard)(_caption!);
      if (!mounted) return;
      setState(() {
        _statusMessage = context.l10n.shareCopied;
        _statusIsError = false;
      });
    } catch (_, stackTrace) {
      if (!mounted) return;
      _showFailure(context.l10n.shareCopyError);
      _reportErrorAfterFeedback(
        const _SharePreviewOperationException('caption_copy_failed'),
        stackTrace,
        reportContext: 'share_caption_copy',
      );
    }
  }

  static Future<void> _copyToClipboard(String caption) =>
      Clipboard.setData(ClipboardData(text: caption));

  void _showFailure(String message) {
    // Kullanıcı geri bildirimi gözlemlenebilirlik hattından bağımsızdır ve
    // raporlama başlatılmadan önce state'e yazılır.
    setState(() {
      _statusMessage = message;
      _statusIsError = true;
    });
  }

  void _reportError(
    Object error,
    StackTrace stackTrace, {
    required String reportContext,
  }) {
    try {
      final report =
          widget.errorReportAction?.call(
            error,
            stackTrace,
            context: reportContext,
          ) ??
          sl<ErrorReporter>().report(error, stackTrace, context: reportContext);
      // Telemetri, kullanıcı geri bildirimini veya sheet etkileşimlerini
      // bekletmez. Sabit context dışında finansal payload gönderilmez.
      unawaited(report.catchError((Object _) {}));
    } catch (_) {
      // DI/raporlama kurulumu da kullanıcı kurtarma yolunu engelleyemez.
    }
  }

  void _reportErrorAfterFeedback(
    Object error,
    StackTrace stackTrace, {
    required String reportContext,
  }) {
    // setState ile yazılan hata önce render edilir; observability sonraki frame
    // başlar ve dönen Future hiçbir zaman etkileşim akışını bekletmez.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportError(error, stackTrace, reportContext: reportContext);
    });
  }

  void _close() {
    _invalidateSession();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () =>
            unawaited(_copyCaption()),
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true): () =>
            unawaited(_copyCaption()),
      },
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height * 0.9;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(
                                l10n.sharePreviewTitle,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ),
                          FocusTraversalOrder(
                            order: const NumericFocusOrder(1),
                            child: Semantics(
                              key: const Key('share-preview-close'),
                              button: true,
                              excludeSemantics: true,
                              label: l10n.sharePreviewClose,
                              onTap: _close,
                              child: IconButton(
                                focusNode: _closeFocusNode,
                                tooltip: l10n.sharePreviewClose,
                                constraints: const BoxConstraints.tightFor(
                                  width: 48,
                                  height: 48,
                                ),
                                onPressed: _close,
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: (maxHeight * 0.36)
                                    .clamp(144.0, 360.0)
                                    .toDouble(),
                                child: LayoutBuilder(
                                  builder: (context, previewConstraints) {
                                    final previewWidth =
                                        previewConstraints.maxWidth;
                                    return Semantics(
                                      container: true,
                                      image: true,
                                      excludeSemantics: true,
                                      label: l10n.sharePreviewCardLabel,
                                      hint: l10n.sharePreviewZoomHint,
                                      child: InteractiveViewer(
                                        key: const Key(
                                          'share-preview-interactive',
                                        ),
                                        constrained: false,
                                        minScale: 1,
                                        maxScale: 4,
                                        boundaryMargin: const EdgeInsets.all(
                                          48,
                                        ),
                                        child: SizedBox(
                                          width: previewWidth,
                                          child: FittedBox(
                                            fit: BoxFit.fitWidth,
                                            alignment: Alignment.topCenter,
                                            child: RepaintBoundary(
                                              key: _repaintKey,
                                              // Yalnızca PNG capture yüzeyi
                                              // sabittir; karar UI'ı sistem
                                              // text scale'ini korur.
                                              child:
                                                  MediaQuery.withClampedTextScaling(
                                                    maxScaleFactor: 1,
                                                    child: widget.cardWidget,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    l10n.shareCaptionTitle,
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: maxHeight * 0.24,
                                ),
                                child: SingleChildScrollView(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: FocusTraversalOrder(
                                      order: const NumericFocusOrder(2),
                                      child: SelectableText(
                                        _caption!,
                                        key: const Key('share-preview-caption'),
                                        focusNode: _captionFocusNode,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_statusMessage case final message?) ...[
                                Semantics(
                                  key: const Key('share-preview-status'),
                                  container: true,
                                  liveRegion: true,
                                  label: message,
                                  child: ExcludeSemantics(
                                    child: Align(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        message,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: _statusIsError
                                                  ? theme.colorScheme.error
                                                  : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: OutlinedButton.icon(
                                  key: const Key('share-preview-copy'),
                                  focusNode: _copyFocusNode,
                                  onPressed: _copyCaption,
                                  icon: const Icon(Icons.copy_outlined),
                                  label: Text(l10n.shareCopyText),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              KeyedSubtree(
                                key: const Key('share-preview-share'),
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(4),
                                  child: FilledButton.icon(
                                    key: _shareButtonKey,
                                    focusNode: _shareFocusNode,
                                    onPressed: _isSharing ? null : _share,
                                    icon: _isSharing
                                        ? _BusyIndicator(
                                            reduceMotion:
                                                MediaQuery.disableAnimationsOf(
                                                  context,
                                                ),
                                          )
                                        : const Icon(Icons.share),
                                    label: Text(
                                      _isSharing
                                          ? l10n.sharingInProgress
                                          : l10n.shareResult,
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator({required this.reduceMotion});

  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return const Icon(Icons.hourglass_top_rounded, size: 18);
    }
    return SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

class _SharePreviewOperationException implements Exception {
  const _SharePreviewOperationException(this.code);

  final String code;

  @override
  String toString() => 'SharePreviewOperationException($code)';
}
