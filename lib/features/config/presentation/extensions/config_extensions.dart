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
  /// F-06-18: `read<AppConfigCubit>()` provider ağaçta yoksa
  /// `ProviderNotFoundException` fırlatır ve UI'yı çökertir. Bunun yerine
  /// güvenle dene; bulunamazsa debug'da açıklayıcı `assert` ile uyar, her iki
  /// modda da [AppConfig.defaultConfig]'e düş (cömert varsayılan — uygulama
  /// çalışmaya devam eder). Cubit'in kendisi de hata durumunda defaultConfig
  /// ile çalıştığından bu, "config her zaman güvenli" sözleşmesini sürdürür.
  AppConfig get appConfig {
    final cubit = _tryReadAppConfigCubit();
    assert(
      cubit != null,
      'AppConfigCubit bulunamadı — BuildContext, AppConfigCubit provider\'ının '
      'altında mı? (MultiBlocProvider app.dart\'ta MaterialApp üstünde sağlar.)',
    );
    return cubit?.state ?? AppConfig.defaultConfig;
  }

  AppConfigCubit? _tryReadAppConfigCubit() {
    try {
      return read<AppConfigCubit>();
    } catch (_) {
      // Tek gerçekçi durum: ProviderNotFoundException (yanlış subtree / test).
      // Geniş catch kasıtlı — her başarısızlıkta güvenli varsayılana düşülür.
      return null;
    }
  }
}
