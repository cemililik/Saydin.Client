import 'package:flutter/material.dart';
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
        // SettingsCubit bir session factory'sidir. DI'dan burada tekrar
        // çözmek, MaterialApp'i yöneten root instance yerine görünmez ikinci
        // bir Cubit oluşturur; dil/tema seçimi ekrana yansımaz. Route her zaman
        // mevcut provider ağacındaki instance'ı paylaşmalıdır.
        final settingsCubit = context.read<SettingsCubit>();
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
