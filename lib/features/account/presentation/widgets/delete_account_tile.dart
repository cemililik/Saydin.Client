import 'package:flutter/material.dart';

import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/account/presentation/pages/delete_account_page.dart';

/// Settings içinde "Hesabımı Sil" navigasyon tile'ı. Tıklanınca onay sayfasına
/// gider — burada doğrudan dialog atmıyoruz çünkü onay yazısı (kelime girme)
/// dialog yerine sayfa olarak daha güvenli ve erişilebilir.
class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = Theme.of(context).colorScheme.error;
    return ListTile(
      leading: Icon(Icons.delete_outline, color: color),
      title: Text(
        l10n.settingsDeleteAccount,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: Icon(Icons.chevron_right, color: color.withAlpha(150)),
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const DeleteAccountPage()),
        );
      },
    );
  }
}
