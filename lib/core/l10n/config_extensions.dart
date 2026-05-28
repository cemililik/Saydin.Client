import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/features/config/domain/entities/app_config.dart';
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart';

extension AppConfigExtension on BuildContext {
  AppConfig get appConfig => read<AppConfigCubit>().state;
}
