import 'package:flutter/material.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/settings/presentation/widgets/language_selector_tile.dart';
import 'package:saydin/features/settings/presentation/widgets/theme_selector_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: const [
          ThemeSelectorTile(),
          Divider(height: 1),
          LanguageSelectorTile(),
        ],
      ),
    );
  }
}
