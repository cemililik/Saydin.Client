import 'package:flutter/material.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/share_card_renderer.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';

class ShareCardPreviewSheet extends StatefulWidget {
  final WhatIfResult result;

  const ShareCardPreviewSheet({super.key, required this.result});

  @override
  State<ShareCardPreviewSheet> createState() => _ShareCardPreviewSheetState();
}

class _ShareCardPreviewSheetState extends State<ShareCardPreviewSheet> {
  final _repaintKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      await ShareCardRenderer.shareFromKey(_repaintKey);
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

            // Kart önizlemesi — FittedBox ile ekrana sığdırılır.
            // RepaintBoundary karta sarılı: renderer boyutu görüntüden hesaplar.
            LayoutBuilder(
              builder: (context, constraints) {
                final previewSize = constraints.maxWidth - 16;
                return SizedBox(
                  width: previewSize,
                  height: previewSize,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: ShareCardWidget(result: widget.result),
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
