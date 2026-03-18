import 'package:flutter/material.dart';
import 'package:saydin/core/widgets/share_preview_sheet.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';

class ShareCardPreviewSheet extends StatelessWidget {
  final WhatIfResult result;
  final String? shareText;

  const ShareCardPreviewSheet({
    super.key,
    required this.result,
    this.shareText,
  });

  @override
  Widget build(BuildContext context) {
    return SharePreviewSheet(
      shareText: shareText,
      cardWidget: ShareCardWidget(result: result),
    );
  }
}
