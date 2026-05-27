import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry'ye giden tüm event ve breadcrumb içeriklerinde finansal PII'yi
/// (asset sembolü, tutar, tarih, kullanıcı tanımlayıcı) sansürleyen savunma katmanı.
///
/// İki kullanım noktası:
/// - `Sentry.init(options.beforeSend)` ve `options.beforeBreadcrumb` —
///   Sentry içine giren her şey için son hat.
/// - `ErrorReporter` içinde `extras` allowlist — call-site'ta erken filtre.
///
/// Kural: bilinmeyen anahtarlar **redact** edilir (`<REDACTED>`), allowlist
/// dışındaki tüm sayı/tarih/sembol pattern'leri string içinde de scrub edilir.
/// Bu hem yeni feature'ların yanlışlıkla PII sızdırmasını engeller hem KVKK
/// uyumu için 6698 sayılı kanun kapsamında veri minimizasyonu sağlar.
class SentryPiiScrubber {
  const SentryPiiScrubber();

  // ── Allowlist'ler ──────────────────────────────────────────────────────────
  // Yeni güvenli anahtar eklemek için: PII içermediğinden emin olun
  // (statik enum/sabit veya tek seferlik teknik telemetri).

  /// `ErrorReporter.report(extras: ...)` ve `Breadcrumb.data` için izinli
  /// anahtarlar. Bu listede olmayan her anahtar redact edilir.
  static const Set<String> allowedKeys = {
    // Teknik telemetri
    'errorType',
    'httpStatus',
    'endpoint', // path-only, no query string
    'method',
    'feature',
    'action',
    'category',
    'retryCount',
    'durationMs',
    'platform',
    'appVersion',
    // Sentry framework ürettiği güvenli anahtarlar
    'level',
    'type',
    'timestamp',
  };

  /// Breadcrumb mesajı için izinli sabit prefix'ler. Bu prefix ile başlayan
  /// mesajlar PII içermediği varsayılarak (callsite'ın anlamlı `action.tag`
  /// formatında geldiği) korunur. Diğer mesajlar boş bırakılır.
  static const Set<String> allowedMessagePrefixes = {
    'what_if.',
    'dca.',
    'portfolio.',
    'comparison.',
    'scenarios.',
    'favorites.',
    'settings.',
    'onboarding.',
    'app.',
  };

  // ── Regex pattern'leri ────────────────────────────────────────────────────
  // String içinde geçen PII kalıplarını yakalar.

  /// ISO 8601 tarih (`2020-01-01`, `2020-01-01T12:34:56.789`, `2020-01-01T12:34:56Z`)
  static final RegExp _isoDate = RegExp(
    r'\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}(\.\d+)?Z?)?',
  );

  /// 4 ve daha fazla haneli sayılar (tutar / fiyat kalıbı).
  /// 3 haneli sayılar (HTTP status, retry sayısı vb.) korunur.
  static final RegExp _largeNumber = RegExp(r'\b\d{4,}([.,]\d+)?\b');

  /// Asset sembolü kalıbı: ALL_CAPS 2-6 harf (BTC, USDTRY, XAU, ETH, THYAO).
  /// Yanlış pozitif riski: TR, US, EN gibi sabitler. Bu nedenle güvenli liste:
  /// `[A-Z]{2,}` sadece kelime sınırında ve diğer büyük harf tokenlerinden uzakta.
  /// Yan kalıp olarak: `[A-Z]{3,6}/[A-Z]{3}` (USDTRY, ETHUSD) ve isolated symbols.
  static final RegExp _assetSymbol = RegExp(r'\b[A-Z]{3,6}([/-][A-Z]{2,4})?\b');

  /// UUID/cihaz tanımlayıcı kalıbı.
  static final RegExp _uuid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  /// E-posta.
  static final RegExp _email = RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b');

  // ── Public API ────────────────────────────────────────────────────────────

  /// Sentry [event]'i için tam scrub. `null` döndürmek event'in atılmasını sağlar
  /// (örn telemetri tamamen reddediliyorsa). Şu an reddetme yok, sadece scrub.
  SentryEvent? scrubEvent(SentryEvent event, Hint hint) {
    // Screenshots'ı zorla kaldır (defensive — options.attachScreenshot=false olsa da).
    hint.attachments.clear();

    return event.copyWith(
      message: event.message == null
          ? null
          : SentryMessage(
              redactText(event.message!.formatted),
              template: event.message!.template,
              params: event.message!.params
                  ?.map((p) => redactText(p.toString()))
                  .toList(growable: false),
            ),
      breadcrumbs: event.breadcrumbs
          ?.map((b) => scrubBreadcrumb(b, hint))
          .whereType<Breadcrumb>()
          .toList(growable: false),
      contexts: _scrubContexts(event.contexts),
      tags: _scrubMap(
        event.tags,
      )?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      request: event.request == null ? null : _scrubRequest(event.request!),
    );
  }

  /// Sentry [breadcrumb] için scrub. `null` döndürmek breadcrumb'ın atılmasını sağlar.
  Breadcrumb? scrubBreadcrumb(Breadcrumb breadcrumb, Hint hint) {
    final message = breadcrumb.message;
    final safeMessage = message == null
        ? null
        : _scrubBreadcrumbMessage(message);

    return Breadcrumb(
      message: safeMessage,
      category: breadcrumb.category,
      data: _scrubMap(breadcrumb.data),
      level: breadcrumb.level,
      type: breadcrumb.type,
      timestamp: breadcrumb.timestamp,
    );
  }

  // ── Public yardımcılar (test ve ErrorReporter için) ────────────────────────

  /// Verilen [map]'ten allowlist dışındaki anahtarları `<REDACTED>` ile değiştirir,
  /// kalan değerlerin string formunda da PII pattern'leri scrub eder.
  Map<String, Object?>? filterAllowedKeys(Map<String, Object?>? map) =>
      _scrubMap(map);

  /// Tek bir [text] üzerinde tarih/sayı/asset sembolü/UUID/e-posta scrub eder.
  String redactText(String text) {
    return text
        .replaceAll(_uuid, '<UUID>')
        .replaceAll(_email, '<EMAIL>')
        .replaceAll(_isoDate, '<DATE>')
        .replaceAll(_largeNumber, '<NUMBER>')
        // Asset sembolü pattern'i çok agresif olmasın; sadece "/" veya "-" içeren
        // pair'ları sansürle. Tek sembol (BTC) ne yazık ki ALL_CAPS sözlük
        // sözcükleriyle çakışıyor; breadcrumb mesajı allowlist'i bu boşluğu kapatır.
        .replaceAllMapped(_assetSymbol, (m) {
          final s = m.group(0)!;
          // Bilinen güvenli ALL_CAPS: HTTP, JSON, API, vs.
          if (_safeAllCaps.contains(s)) return s;
          return '<SYMBOL>';
        });
  }

  // ── İç implementasyon ────────────────────────────────────────────────────

  static const Set<String> _safeAllCaps = {
    // Sentinel sözcükler — scrubber'ın kendi ürettiği `<DATE>`, `<UUID>` vs.
    // içindeki ALL_CAPS isim `_assetSymbol` regex'ine düşmesin.
    'DATE',
    'NUMBER',
    'SYMBOL',
    'UUID',
    'EMAIL',
    'REDACTED',
    // Standart teknik terimler
    'HTTP',
    'HTTPS',
    'JSON',
    'API',
    'URL',
    'URI',
    'IO',
    'IP',
    'DNS',
    'TCP',
    'SSL',
    'TLS',
    'GET',
    'POST',
    'PUT',
    'DELETE',
    'PATCH',
    'HEAD',
    'OPTIONS',
    'KVKK',
    'TUFE',
    'BIST',
    'TRY', // Türk Lirası — tutar değil, currency code; pratikte güvenli.
    'OK',
    'OS',
    'CPU',
    'RAM',
    'SDK',
    'BLOC',
    'UI',
    'UX',
    'CI',
    'CD',
    'PR',
    'ID',
    'TR',
    'EN',
    'US',
  };

  Map<String, Object?>? _scrubMap(Map<String, Object?>? input) {
    if (input == null) return null;
    final out = <String, Object?>{};
    for (final entry in input.entries) {
      if (allowedKeys.contains(entry.key)) {
        out[entry.key] = _scrubValue(entry.value);
      } else {
        out[entry.key] = '<REDACTED>';
      }
    }
    return out;
  }

  Object? _scrubValue(Object? value) {
    if (value == null) return null;
    if (value is String) return redactText(value);
    if (value is num || value is bool) return value;
    if (value is List) return value.map(_scrubValue).toList(growable: false);
    if (value is Map<String, Object?>) return _scrubMap(value);
    return redactText(value.toString());
  }

  String _scrubBreadcrumbMessage(String message) {
    final isAllowed = allowedMessagePrefixes.any(message.startsWith);
    if (!isAllowed) return '<REDACTED>';
    // Allowlist prefix ile başlasa bile ek serbest metin redaksiyona tabi.
    // Örn: 'what_if.calculated: BTC 2020-01-01' → 'what_if.calculated: <SYMBOL> <DATE>'
    return redactText(message);
  }

  Contexts _scrubContexts(Contexts contexts) {
    // Contexts içindeki yapılandırılmış alanlar (device, app, runtime) PII içermez.
    // Bizim eklediğimiz `setContexts('extra', map)` allowlist'ten geçer.
    final scrubbed = Contexts();
    contexts.forEach((key, value) {
      if (value == null) {
        scrubbed[key] = null;
        return;
      }
      if (value is Map<String, Object?>) {
        scrubbed[key] = _scrubMap(value);
      } else {
        scrubbed[key] = value;
      }
    });
    return scrubbed;
  }

  SentryRequest _scrubRequest(SentryRequest request) {
    final url = request.url;
    return request.copyWith(
      url: url == null ? null : _scrubUrl(url),
      queryString: null, // query string yutulur, asla loglanmaz
      cookies: null,
      data: null,
      headers: Map.fromEntries(
        request.headers.entries.where(
          (e) => _safeHeaders.contains(e.key.toLowerCase()),
        ),
      ),
    );
  }

  static const Set<String> _safeHeaders = {
    'content-type',
    'accept',
    'accept-language',
    'user-agent',
  };

  String _scrubUrl(String url) {
    // Query string ve path parametrelerini sansürle.
    final idx = url.indexOf('?');
    final base = idx >= 0 ? url.substring(0, idx) : url;
    // Path'ten UUID'leri sansürle.
    return base.replaceAll(_uuid, '<UUID>');
  }
}
