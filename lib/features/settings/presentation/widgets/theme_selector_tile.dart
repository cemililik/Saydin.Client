import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/settings/domain/entities/app_settings.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';

class ThemeSelectorTile extends StatelessWidget {
  const ThemeSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentMode = context.watch<SettingsCubit>().state.themeMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_iconFor(currentMode), size: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.settingsTheme,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    l10n.settingsThemeSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              segments: [
                ButtonSegment(
                  value: AppThemeMode.light,
                  icon: const Icon(Icons.light_mode, size: 18),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: AppThemeMode.dark,
                  icon: const Icon(Icons.dark_mode, size: 18),
                  label: Text(l10n.themeDark),
                ),
                ButtonSegment(
                  value: AppThemeMode.system,
                  icon: const Icon(Icons.settings_brightness, size: 18),
                  label: Text(l10n.themeSystem),
                ),
              ],
              selected: {currentMode},
              onSelectionChanged: (selection) {
                context.read<SettingsCubit>().setThemeMode(selection.first);
              },
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.light => Icons.light_mode,
      AppThemeMode.dark => Icons.dark_mode,
      AppThemeMode.system => Icons.settings_brightness,
    };
  }
}
