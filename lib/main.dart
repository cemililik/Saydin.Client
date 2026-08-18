import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/observability/sentry_device_context.dart';
import 'core/observability/sentry_pii_scrubber.dart';
import 'core/platform/platform_info.dart';
import 'core/utils/share_card_renderer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const scrubber = SentryPiiScrubber();

  // ── Küresel hata yakalama (F-05-02) ────────────────────────────────────────
  // `SentryFlutter.init(appRunner:)` uygulamayı `runZonedGuarded` İÇİNDE
  // çalıştırır ve `FlutterError.onError` + `PlatformDispatcher.instance.onError`
  // kancalarını otomatik bağlar. Böylece üç sınıf hata da yakalanıp Sentry'ye
  // gider: (1) Flutter framework (build/layout) hataları, (2) yakalanmamış
  // async/zone hataları, (3) platform (engine) hataları.
  //
  // Başlangıç işleri (`initializeDateFormatting`, `configureDependencies`,
  // temizlik, scope) `appRunner` İÇİNE alınır: `runApp`'ten ÖNCE oluşan init
  // hataları (örn. `ApiBaseUrlValidator`'ın release'de fırlattığı `StateError`)
  // da aynı guard'a düşsün — eskiden bu işler Sentry init'inden önce, korumasız
  // çalışıyordu ve sessiz beyaz-ekran crash'i üretebiliyordu.
  //
  // Manuel ikinci bir `runZonedGuarded` EKLENMEZ: Sentry'nin zone'unu sarmalar
  // ve aynı hatayı iki kez raporlardı.
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
      const release = String.fromEnvironment('SENTRY_RELEASE');
      const dist = String.fromEnvironment('SENTRY_DIST');
      if (release.isNotEmpty) options.release = release;
      if (dist.isNotEmpty) options.dist = dist;
      // Performance transaction/span payload'ları; description, data ve
      // measurement alanlarında serbest metin taşıyabilir. Bunlar için gerçek
      // serialized-envelope sözleşme testi kurulana kadar tracing fail-closed
      // kapalıdır; crash/error event'leri normal biçimde devam eder.
      options.tracesSampleRate = 0.0;
      // Native auto-session envelopes Dart beforeSend scrubber'ının dışında
      // oluşabilir. Serialized envelope sözleşmesi ayrıca doğrulanana kadar
      // release-health session tracking'i fail-closed kapalı tut.
      options.enableAutoSessionTracking = false;
      // SDK varsayılanı null/disabled olsa da upgrade drift'ine karşı replay'i
      // explicit kapat. Finansal sonuç ekranı kaydı hiçbir build'de üretilmez.
      // ignore: experimental_member_use
      options.experimental.replay.sessionSampleRate = 0.0;
      // ignore: experimental_member_use
      options.experimental.replay.onErrorSampleRate = 0.0;

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
      // İleride tracing tekrar etkinleştirilirse transaction event'leri de
      // aynı scrub yolundan geçer. Bu callback `Hint` almaz; boş Hint
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
    appRunner: () async {
      // `null` ile tüm desteklenen locale verilerini yükler. EN locale'de
      // `DateFormat.yMMMMd('en_US')` çağrısı (örn `LegalDocumentPage`) data
      // yüklenmemişse runtime'da çöker. Sadece `'tr_TR'` yüklemek bu nedenle
      // EN tarafını kırıyordu.
      await initializeDateFormatting();
      await configureDependencies();
      // 1 saatten eski paylaşım kart PNG'lerini temizle. Önceki oturumda share
      // iletişim kutusu kapanmadan uygulama kapatıldıysa renderer'ın finally
      // bloğu çalışmaz — startup pass ikinci savunma hattı (KVKK Madde 12).
      unawaited(ShareCardRenderer.cleanupStaleShareFiles());
      // PII olmayan cihaz/uygulama etiketlerini Sentry scope'una ekle (F-05-07).
      // M-5: bu KRİTİK OLMAYAN telemetri adımı `runApp`'i bloke etmemeli — aksi
      // halde scope yazımındaki beklenmeyen bir hata kullanıcıyı beyaz ekranda
      // bırakır. sl<>() çözümlemesi try DIŞINDA: DI hatası (kritik) hâlâ
      // fail-fast; yalnızca Sentry scope yazımı izole edilir.
      final packageInfo = sl<PackageInfo>();
      final platformInfo = sl<PlatformInfo>();
      try {
        await configureSentryDeviceScope(
          packageInfo: packageInfo,
          platform: platformInfo,
        );
      } catch (e, st) {
        await Sentry.captureException(e, stackTrace: st);
      }
      runApp(
        DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: const SaydinApp(),
        ),
      );
    },
  );
}
