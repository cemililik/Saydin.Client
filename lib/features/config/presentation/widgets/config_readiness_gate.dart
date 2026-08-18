import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';

/// Uygulamanın plan ve feature-flag'a bağlı arayüzünü config çözülene kadar
/// bekletir.
///
/// Bu kapı, cold start sırasında varsayılan `free` config ile istek atılmasını
/// engeller. Config isteği başarısız olduğunda cubit güvenli fallback'i
/// `isReady: true` olarak emit eder; kullanıcı yükleme ekranında kilitli
/// kalmaz.
class ConfigReadinessGate extends StatefulWidget {
  const ConfigReadinessGate({super.key, required this.child});

  final Widget child;

  @override
  State<ConfigReadinessGate> createState() => _ConfigReadinessGateState();
}

class _ConfigReadinessGateState extends State<ConfigReadinessGate> {
  @override
  void initState() {
    super.initState();
    // Bu widget yalnız onboarding + güncel legal bildirim tamamlandıktan sonra
    // ağaçta yer alır. Config'in ilk ağ isteğini burada başlatmak startup veri
    // işleme sırasını teknik olarak garanti eder.
    context.read<AppConfigCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppConfigCubit, AppConfig>(
      builder: (context, config) {
        if (config.isReady) return widget.child;

        final label = context.l10n.configLoading;
        return Scaffold(
          body: Center(
            child: Semantics(
              liveRegion: true,
              label: label,
              child: const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
