import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:saydin/core/observability/sentry_pii_scrubber.dart';

/// Sentry'ye finansal PII sızdırmadan hata ve kullanıcı eylemi raporlayan
/// observability fasadı. Test ortamında mock'lanabilir (concrete class — varolan
/// kodu kırmamak için).
///
/// Defense-in-depth: call-site'tan gönderilen tüm [extras] ve [data]
/// içerikleri burada da [SentryPiiScrubber] üzerinden geçirilir; böylece
/// `beforeSend` kancası unutulsa bile PII redact edilir.
class ErrorReporter {
  const ErrorReporter({SentryPiiScrubber scrubber = const SentryPiiScrubber()})
    : _scrubber = scrubber;

  final SentryPiiScrubber _scrubber;

  /// Yakalanmış istisnayı Sentry'ye raporlar. [extras] sadece
  /// [SentryPiiScrubber.allowedKeys] içindeki anahtarlarla geçer; geri kalan
  /// her şey `<REDACTED>` olur.
  Future<void> report(
    Object exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, Object?>? extras,
  }) async {
    final safeExtras = _scrubber.filterAllowedKeys(extras);
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (context != null) {
          scope.setTag('context', context);
        }
        if (safeExtras != null && safeExtras.isNotEmpty) {
          // SDK'nin typed `app` context'iyle çakışmayan, scrubber'ın açıkça
          // allowlist'e aldığı tek custom namespace. Böylece `beforeSend`
          // typed context'leri deny-by-default drop ederken bu şemalı teknik
          // alanlar korunur.
          scope.setContexts('app_telemetry', safeExtras);
        }
      },
    );
  }

  /// Yapısal kullanıcı eylemi breadcrumb'ı.
  ///
  /// [action] zorunlu olarak `<feature>.<verb>` formatında sabit string olmalıdır
  /// (örn `what_if.calculated`, `dca.failed`, `scenarios.deleted`). Kullanıcı
  /// girdileri (asset sembolü, tutar, tarih) **bu parametreye yazılamaz**.
  ///
  /// [data] içindeki anahtarlar [SentryPiiScrubber.allowedKeys] allowlist'inden
  /// geçer; teknik telemetri için (httpStatus, durationMs vb.) kullanılır.
  Future<void> recordAction(
    String action, {
    String? category,
    Map<String, Object?>? data,
  }) async {
    // Geliştirici uyarısı: release modda assert devre dışıdır ama
    // güvenlik garantisi `SentryPiiScrubber._scrubBreadcrumbMessage`
    // tarafından her iki modda da uygulanır: allowlist prefix'te olmayan
    // her mesaj `<REDACTED>` olur. Yani burada bypass riski yok; assert
    // sadece debug sırasında geliştiriciye yanlış prefix'i bildirir.
    assert(
      SentryPiiScrubber.allowedMessagePrefixes.any(action.startsWith),
      "Breadcrumb action must start with a known feature prefix "
      "(what_if., dca., portfolio., ...). Got: $action",
    );
    final safeData = _scrubber.filterAllowedKeys(data);
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: action,
        category: category ?? 'app',
        data: safeData,
        level: SentryLevel.info,
      ),
    );
  }

  /// @deprecated [recordAction] kullanın. PII içeren çağrılar için geriye uyumluluk
  /// köprüsü; mesaj scrubber tarafından sansürlenir, ancak yapı kaybedilir.
  @Deprecated('Use recordAction with a structured action key + data map')
  Future<void> addBreadcrumb(String message, {String? category}) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(
        // Mesajı PII açısından scrub et — call-site sızıntısına karşı son hat.
        message: _scrubber.redactText(message),
        category: category ?? 'app',
      ),
    );
  }

  /// Hesap silme / wipe akışında çağrılır. Sentry scope'undaki tüm
  /// breadcrumb, user, tag ve context bilgisini siler — sonraki bir
  /// crash event'i eski `X-Device-ID`'yi veya kullanıcı eylem geçmişini
  /// taşımaz. KVKK Madde 11 silme hakkının teknik karşılığı.
  ///
  /// `scope.clear()` çağrısı in-memory state'i temizler; ağda hâlihazırda
  /// uçuşta olan bir event varsa onu geri alamayız, ancak sonraki olayların
  /// silinen kullanıcıyla ilişkilendirilmesini engelleriz.
  Future<void> clearScope() async {
    await Sentry.configureScope((scope) async {
      await scope.clear();
    });
  }
}
