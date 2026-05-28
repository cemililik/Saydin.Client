import 'package:flutter/material.dart';
import 'package:saydin/core/widgets/share_preview_sheet.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';

class ShareCardPreviewSheet extends StatelessWidget {
  final WhatIfResult? result;
  final Widget? cardWidgetOverride;
  final String? shareText;

  const ShareCardPreviewSheet({
    super.key,
    this.result,
    this.cardWidgetOverride,
    this.shareText,
  });

  @override
  Widget build(BuildContext context) {
    final card =
        cardWidgetOverride ??
        (result != null
            ? ShareCardWidget(result: result!)
            : const SizedBox.shrink());
    return SharePreviewSheet(shareText: shareText, cardWidget: card);
  }
}
