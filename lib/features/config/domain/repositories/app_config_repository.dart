import 'package:saydin/features/config/domain/entities/app_config.dart';

abstract interface class AppConfigRepository {
  Future<AppConfig> getConfig();
}
