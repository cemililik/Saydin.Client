import 'package:saydin/features/config/domain/entities/app_config.dart';

/// Paylaşım girişlerinin uygulama genelindeki tek yetkilendirme politikası.
///
/// Yalnızca uzaktan doğrulanmış config paylaşımı açabilir. Config yüklenirken
/// veya endpoint hatası sonrası genel uygulama fallback ile çalışsa bile uzak
/// kill-switch'in güncel değeri kanıtlanamadığından paylaşım fail-closed kalır.
abstract final class SharePolicy {
  const SharePolicy._();

  static bool canShare(AppConfig config) =>
      config.readiness == AppConfigReadiness.ready && config.features.share;

  /// Görünürlük kontrolünden sonra config değişmiş olabileceği için paylaşım
  /// callback'i çalıştırılacağı anda politikayı yeniden uygular.
  static bool runIfAllowed(AppConfig config, void Function() onAllowed) {
    if (!canShare(config)) return false;
    onAllowed();
    return true;
  }
}
