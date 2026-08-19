import 'package:flutter/material.dart';
import 'package:saydin/core/widgets/share_preview_sheet.dart';
import 'package:saydin/features/dca/domain/entities/dca_result.dart';
import 'package:saydin/features/dca/presentation/widgets/dca_share_card_widget.dart';

class DcaShareCardPreviewSheet extends StatelessWidget {
  final DcaResult result;
  final String? shareText;
  final ShareAuthorization canExecuteShare;

  const DcaShareCardPreviewSheet({
    super.key,
    required this.result,
    this.shareText,
    required this.canExecuteShare,
  });

  @override
  Widget build(BuildContext context) {
    return SharePreviewSheet(
      shareText: shareText,
      cardWidget: DcaShareCardWidget(result: result),
      canExecuteShare: canExecuteShare,
    );
  }
}
