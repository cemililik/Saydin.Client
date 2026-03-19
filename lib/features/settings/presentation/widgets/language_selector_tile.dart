import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';

class LanguageSelectorTile extends StatelessWidget {
  const LanguageSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentLang = context.watch<SettingsCubit>().state.language;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(currentLang), size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsLanguage,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    l10n.settingsLanguageSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppLanguage>(
              segments: [
                ButtonSegment(
                  value: AppLanguage.tr,
                  label: Text(l10n.languageTurkish),
                ),
                ButtonSegment(
                  value: AppLanguage.en,
                  label: Text(l10n.languageEnglish),
                ),
                ButtonSegment(
                  value: AppLanguage.system,
                  icon: const Icon(Icons.phone_android, size: 18),
                  label: Text(l10n.languageSystem),
                ),
              ],
              selected: {currentLang},
              onSelectionChanged: (selection) {
                context.read<SettingsCubit>().setLanguage(selection.first);
              },
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AppLanguage lang) {
    return switch (lang) {
      AppLanguage.tr => Icons.translate,
      AppLanguage.en => Icons.translate,
      AppLanguage.system => Icons.phone_android,
    };
  }
}
