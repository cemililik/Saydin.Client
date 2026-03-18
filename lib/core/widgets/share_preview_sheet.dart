import 'package:flutter/material.dart';
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
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              l10n.sharePreviewTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Kart önizlemesi — FittedBox ile genişliğe sığdırılır.
            LayoutBuilder(
              builder: (context, constraints) {
                final previewWidth = constraints.maxWidth - 16;
                return SizedBox(
                  width: previewWidth,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: widget.cardWidget,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _isSharing ? null : _share,
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
  }
}
