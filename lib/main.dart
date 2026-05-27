import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/observability/sentry_pii_scrubber.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  await configureDependencies();

  const scrubber = SentryPiiScrubber();

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        // DSN yoksa Sentry devre dışı kalır (no-op send).
        defaultValue: '',
      );
      options.environment = const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      );
      options.tracesSampleRate = 0.2; // %20 performance tracing

      // ── Gizlilik (KVKK 6698 / GDPR) ────────────────────────────────────────
      // Finansal "ya alsaydım" ekranlarındaki tutar, asset ve tarih
      // bilgileri kişisel veri sayılır. Hiçbir koşulda Sentry'ye
      // gitmemelidir. Üç katman:
      //   1) attachScreenshot=false — ekran görüntüsü hiç oluşturulmaz.
      //   2) sendDefaultPii=false   — IP, kullanıcı kimliği vs. eklenmez.
      //   3) beforeSend/beforeBreadcrumb — kalan tüm event/breadcrumb içerikleri
      //      `SentryPiiScrubber` üzerinden geçer (tarih/tutar/sembol regex
      //      sansürü + allowlist anahtarlar).
      options.attachScreenshot = false;
      // attachViewHierarchy: API hâlâ experimental; default false. SDK GA olunca
      // burada explicit false olarak işaretlenecek.
      options.sendDefaultPii = false;

      options.beforeSend = (event, hint) async =>
          scrubber.scrubEvent(event, hint);
      // `tracesSampleRate > 0` olduğu için transaction event'leri de Sentry'ye
      // gider — bunlar `SentryTransaction extends SentryEvent` olduğundan
      // aynı scrub yolundan geçirilir. Bu callback `Hint` almaz; boş Hint
      // oluşturup geçeriz.
      options.beforeSendTransaction = (transaction) async {
        final scrubbed = scrubber.scrubEvent(transaction, Hint());
        return scrubbed is SentryTransaction ? scrubbed : null;
      };
      options.beforeBreadcrumb = (breadcrumb, hint) {
        if (breadcrumb == null) return null;
        return scrubber.scrubBreadcrumb(breadcrumb, hint);
      };
    },
    appRunner: () => runApp(
      DefaultAssetBundle(bundle: SentryAssetBundle(), child: const SaydinApp()),
    ),
  );
}
