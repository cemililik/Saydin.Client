import 'package:flutter/material.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/share_card_renderer.dart';

/// Herhangi bir paylaşım kartı widget'ı için önizleme sayfası.
/// WhatIf, Karşılaştırma ve Portföy ekranları bu widget'ı paylaşır.
class SharePreviewSheet extends StatefulWidget {
  final Widget cardWidget;
  final String? shareText;

  const SharePreviewSheet({
    super.key,
    required this.cardWidget,
    this.shareText,
  });

  @override
  State<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<SharePreviewSheet> {
  final _repaintKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      await ShareCardRenderer.shareFromKey(
        _repaintKey,
        shareText: widget.shareText,
        context: context,
      );
    } on ShareCardException catch (e, st) {
      // F-05-22: render başarısız — kullanıcıya geri bildir + raporla.
      await sl<ErrorReporter>().report(e, st, context: 'share_card_render');
      _showShareError();
    } catch (e, st) {
      // Beklenmeyen paylaşım hatası (platform/share plugin) — sessizce yutma.
      await sl<ErrorReporter>().report(e, st, context: 'share_card');
      _showShareError();
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showShareError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.shareError),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height * 0.9;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Text(
                    l10n.sharePreviewTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Kart önizlemesi — FittedBox ile genişliğe sığdırılır.
                  Expanded(
                    child: SingleChildScrollView(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final previewWidth = constraints.maxWidth - 16;
                          return SizedBox(
                            width: previewWidth,
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.topCenter,
                              child: RepaintBoundary(
                                key: _repaintKey,
                                // Capture yüzeyi sabit tasarlanır; sheet'in
                                // başlık ve CTA'sı sistem text scale'ini
                                // korurken görsel içeriği taşmaz.
                                child: MediaQuery.withClampedTextScaling(
                                  maxScaleFactor: 1,
                                  child: widget.cardWidget,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: _isSharing ? null : _share,
                    icon: _isSharing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.share),
                    label: Text(
                      _isSharing ? l10n.sharingInProgress : l10n.shareResult,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
