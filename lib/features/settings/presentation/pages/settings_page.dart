import 'package:flutter/material.dart';

import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/turkish_text.dart';
import 'package:saydin/features/account/presentation/widgets/delete_account_tile.dart';
import 'package:saydin/features/legal/domain/entities/legal_document.dart';
import 'package:saydin/features/legal/presentation/widgets/legal_tile.dart';
import 'package:saydin/features/settings/presentation/widgets/language_selector_tile.dart';
import 'package:saydin/features/settings/presentation/widgets/reset_preferences_tile.dart';
import 'package:saydin/features/settings/presentation/widgets/theme_selector_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // ── Tercihler ─────────────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsSectionPreferences),
          const ThemeSelectorTile(),
          const Divider(height: 1),
          const LanguageSelectorTile(),

          // ── Yasal ─────────────────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsSectionLegal),
          LegalTile(
            type: LegalDocumentType.privacyPolicy,
            title: l10n.settingsPrivacyPolicy,
            leading: const Icon(Icons.privacy_tip_outlined),
          ),
          const Divider(height: 1),
          LegalTile(
            type: LegalDocumentType.kvkkDisclosure,
            title: l10n.settingsKvkkDisclosure,
            leading: const Icon(Icons.policy_outlined),
          ),

          // ── Hesap ────────────────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsSectionAccount),
          const DeleteAccountTile(),
          const Divider(height: 1),
          const ResetPreferencesTile(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Türkçe-aware uppercase yalnızca TR locale'de uygulanır. EN locale'de
    // `toUpperCaseTr('Preferences')` → `'PREFERİNCES'` (yanlış dotted İ)
    // üretir. Locale kontrolü ile sadece TR'de Türkçe büyütme kullanılır.
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    final upperLabel = isTurkish ? toUpperCaseTr(label) : label.toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        upperLabel,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
