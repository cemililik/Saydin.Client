import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';

/// `context.appConfig` ile aktif [AppConfig]'e kısa erişim.
///
/// Konum: config **feature**'ının presentation katmanı. (Önceden
/// `core/l10n/` altındaydı; core'un bir feature'ı import etmesi katman
/// ihlaliydi — F-12-22.)
extension AppConfigExtension on BuildContext {
  AppConfig get appConfig => read<AppConfigCubit>().state;
}
