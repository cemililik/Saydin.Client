import 'package:flutter/material.dart';
import 'package:saydin/core/widgets/share_preview_sheet.dart';
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart';
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart';

class ShareCardPreviewSheet extends StatelessWidget {
  final Widget cardWidget;
  final String? shareText;
  final ShareAuthorization canExecuteShare;

  ShareCardPreviewSheet.normal({
    super.key,
    required WhatIfResult result,
    this.shareText,
    required this.canExecuteShare,
  }) : cardWidget = ShareCardWidget(result: result);

  const ShareCardPreviewSheet.custom({
    super.key,
    required this.cardWidget,
    this.shareText,
    required this.canExecuteShare,
  });

  @override
  Widget build(BuildContext context) => SharePreviewSheet(
    shareText: shareText,
    cardWidget: cardWidget,
    canExecuteShare: canExecuteShare,
  );
}
