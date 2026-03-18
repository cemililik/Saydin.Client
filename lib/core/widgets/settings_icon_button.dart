import 'package:flutter/material.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:saydin/features/settings/presentation/pages/settings_page.dart';

class SettingsIconButton extends StatelessWidget {
  const SettingsIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      onPressed: () {
        final settingsCubit = sl<SettingsCubit>();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: settingsCubit,
              child: const SettingsPage(),
            ),
          ),
        );
      },
    );
  }
}
