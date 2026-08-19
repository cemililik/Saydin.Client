import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/config/domain/policies/share_policy.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';

/// Sonuç satırlarında kullanılan, feature policy kontrollü paylaşım alanı.
///
/// Bu widget doğrudan bir [Row] çocuğu olarak kullanılmalıdır. Paylaşım kapalı
/// veya config henüz hazır değilken hiç yer kaplamaz. Tıklama anında güncel
/// config yeniden okunur; görünürken kapanmış bir flag eski callback üzerinden
/// paylaşım önizlemesini açamaz.
class ShareResultButton extends StatelessWidget {
  const ShareResultButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigCubit>().state;
    if (!SharePolicy.canShare(config)) return const SizedBox.shrink();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: OutlinedButton.icon(
          onPressed: enabled
              ? () => SharePolicy.runIfAllowed(
                  context.read<AppConfigCubit>().state,
                  onPressed,
                )
              : null,
          icon: const Icon(Icons.share_outlined),
          label: Text(context.l10n.shareResult),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
