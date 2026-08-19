import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry'ye giden tüm event ve breadcrumb içeriklerinde finansal PII'yi
/// (asset sembolü, tutar, tarih, kullanıcı tanımlayıcı) sansürleyen savunma katmanı.
///
/// İki kullanım noktası:
/// - `Sentry.init(options.beforeSend / beforeBreadcrumb / beforeSendTransaction)` —
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
    'backendOk',
    // Yalnızca uygulamanın kendi, şeması doğrulanan scope tag'leri.
    'os',
    'os_version',
    'app_version',
    'context',
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

  /// Serbest metindeki sayı pattern'i. Bir sayının finansal tutar mı yoksa
  /// teknik değer mi olduğunu event mesajında güvenilir biçimde ayıramayız;
  /// bu yüzden **bütün** sayılar redakte edilir. HTTP status/retry/duration
  /// gibi ihtiyaç duyulan teknik sayılar yalnızca şeması doğrulanan yapılandırılmış
  /// allowlist alanlarında tutulabilir.
  ///
  /// Türkçe/İngilizce ondalık ve binlik biçimlerini de kapsar.
  static final RegExp _largeNumber = RegExp(r'\b\d+(?:[.,]\d+)*\b');

  /// Asset sembolü kalıbı (pair): `USD/TRY`, `BTC-USD`, `ETH/USDT`.
  static final RegExp _assetSymbol = RegExp(r'\b[A-Z]{3,6}[/-][A-Z]{2,6}\b');

  /// Tek sembol asset (BTC, USDTRY, XAUTRY, ETHUSDT). Yatırım bağlamında
  /// PII sayılır — kullanıcı portföy/seçimini ima eder. `_safeAllCaps`
  /// allowlist'inde olmayan 3-8 harfli ALL_CAPS token'ları sansürler.
  /// `_assetSymbol` (pair) önce çalışır, bu pattern artakalanları yakalar.
  static final RegExp _assetSymbolSingle = RegExp(r'\b[A-Z]{3,8}\b');

  /// UUID/cihaz tanımlayıcı kalıbı.
  static final RegExp _uuid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  /// E-posta.
  static final RegExp _email = RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b');

  /// T.C. Kimlik Numarası — 11 ardışık rakam, kelime sınırlarıyla. Başında
  /// `0` olamaz ama burada katı olmadan tüm 11-rakam blokunu sansürleriz.
  static final RegExp _tcKimlik = RegExp(r'\b\d{11}\b');

  /// IBAN: TR + 24 alfanumerik. Türkiye için sabit uzunluk.
  static final RegExp _iban = RegExp(r'\bTR\d{2}[A-Z0-9]{22}\b');

  /// TR telefon (mobil/sabit) — `+90...`, `0090...`, `0XXX...`, 10 hane.
  /// Sade yaklaşım: 11 haneli `0` ile başlayan numaralar + uluslararası
  /// `+90` formatı.
  static final RegExp _phoneTr = RegExp(
    r'(?:\+?90[\s-]?)?0?5\d{2}[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}',
  );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Sentry [event]'i için tam scrub. `null` döndürmek event'in atılmasını sağlar
  /// (örn telemetri tamamen reddediliyorsa). Şu an reddetme yok, sadece scrub.
  ///
  /// `SentryTransaction extends SentryEvent`; ancak `SentryEvent.copyWith` tip
  /// slicing yapar (`SentryTransaction` runtime tipini korumaz). Bu nedenle
  /// transaction'ları `SentryTransaction.copyWith` üzerinden scrub'larız ve
  /// kendi tipinde döndürürüz — yoksa `beforeSendTransaction` tüm
  /// transaction'ları sessizce drop eder ve performance tracing devre dışı kalır.
  SentryEvent? scrubEvent(SentryEvent event, Hint hint) {
    _stripScreenshotAndViewHierarchy(hint);

    if (event is SentryTransaction) {
      return event.copyWith(
        transaction: event.transaction == null
            ? null
            : redactText(event.transaction!),
        breadcrumbs: event.breadcrumbs
            ?.map((b) => scrubBreadcrumb(b, hint))
            .whereType<Breadcrumb>()
            .toList(growable: false),
        contexts: _scrubContexts(event.contexts),
        tags: _scrubMap(
          event.tags,
        )?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        // ignore: deprecated_member_use
        extra: _scrubMap(event.extra),
        // SentryEvent branch'iyle simetri: transaction'larda da exception/
        // fingerprint alanları PII içerebilir (örn child span'lerin error
        // payload'ları, custom fingerprint stringleri).
        fingerprint: event.fingerprint?.map(redactText).toList(growable: false),
        exceptions: event.exceptions
            ?.map(_scrubException)
            .toList(growable: false),
        user: _scrubUser(event.user),
        request: event.request == null ? null : _scrubRequest(event.request!),
      );
    }

    return event.copyWith(
      message: _scrubMessage(event.message),
      transaction: event.transaction == null
          ? null
          : redactText(event.transaction!),
      breadcrumbs: event.breadcrumbs
          ?.map((b) => scrubBreadcrumb(b, hint))
          .whereType<Breadcrumb>()
          .toList(growable: false),
      contexts: _scrubContexts(event.contexts),
      tags: _scrubMap(
        event.tags,
      )?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      // `extra` SDK tarafından deprecated ama mevcut sürümde hâlâ
      // serialize edilir. Eski kod (örn 3rd party plugin) bu alanı
      // doldurabilir; defense-in-depth scrub'ı kapatamayız.
      // ignore: deprecated_member_use
      extra: _scrubMap(event.extra),
      fingerprint: event.fingerprint?.map(redactText).toList(growable: false),
      user: _scrubUser(event.user),
      request: event.request == null ? null : _scrubRequest(event.request!),
      exceptions: event.exceptions
          ?.map(_scrubException)
          .toList(growable: false),
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

  /// Tek bir [text] üzerinde tarih/sayı/asset sembolü/UUID/e-posta/TC/IBAN/
  /// telefon scrub eder. Sıra önemli: önce daha spesifik pattern'ler
  /// (UUID, e-posta, IBAN, telefon, TC) — sonra genel (sayı, sembol).
  String redactText(String text) {
    return text
        .replaceAll(_uuid, '<UUID>')
        .replaceAll(_email, '<EMAIL>')
        .replaceAll(_iban, '<IBAN>')
        .replaceAll(_phoneTr, '<PHONE>')
        .replaceAll(_tcKimlik, '<TCKN>')
        .replaceAll(_isoDate, '<DATE>')
        .replaceAll(_largeNumber, '<NUMBER>')
        .replaceAllMapped(_assetSymbol, (m) {
          final s = m.group(0)!;
          // Composite kontrolü: `USER-AGENT`, `HTTP-GET` gibi birleşik
          // teknik terimler `_safeAllCaps`'te tek tek var ama birleşik
          // hâlde yok. Pair'i `/` veya `-` üzerinden böl; tüm parçaları
          // güvenli ise mesajı sansürleme.
          final parts = s.split(_assetSymbolSeparator);
          if (parts.every(_safeAllCaps.contains)) return s;
          return '<SYMBOL>';
        })
        .replaceAllMapped(_assetSymbolSingle, (m) {
          final s = m.group(0)!;
          if (_safeAllCaps.contains(s)) return s;
          return '<SYMBOL>';
        });
  }

  /// `_assetSymbol` pattern'inde kullanılan ayraç (`/` veya `-`).
  static final RegExp _assetSymbolSeparator = RegExp(r'[/-]');

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
    // `User-Agent`, `X-Forwarded-For` gibi header isimlerinde sık geçen
    // composite parça'lar. `_assetSymbol` regex'i tüm parçalar safe ise
    // birleşiği de korur.
    'USER',
    'AGENT',
    'X',
    'FORWARDED',
    'FOR',
  };

  /// Defense-in-depth: `options.attachScreenshot=false` olsa bile,
  /// `beforeSend` çağrıldığında bu Hint alanlarının dolu olabileceği SDK
  /// dahili akışları (manuel `Sentry.captureUserFeedback`, plugin'ler) var.
  /// Burada zorla null'larız.
  void _stripScreenshotAndViewHierarchy(Hint hint) {
    hint.attachments.clear();
    hint.screenshot = null;
    hint.viewHierarchy = null;
  }

  SentryMessage? _scrubMessage(SentryMessage? message) {
    if (message == null) return null;
    return SentryMessage(
      redactText(message.formatted),
      // `template`, serialize edilir ve ham kullanıcı girdisi/finansal veri
      // içerebilir. Sadece `formatted` alanını temizlemek yeterli değildir.
      template: message.template == null ? null : redactText(message.template!),
      params: message.params
          // Parametrelerin string olmayan türleri SDK tarafından toString() ile
          // serialize edilebilir. Bunu kabul etmek typed-context bypass'ına
          // denktir; serbest değerleri deny-by-default reddederiz.
          ?.map((p) => p is String ? redactText(p) : '<REDACTED>')
          .toList(growable: false),
    );
  }

  /// Exception type+value scrub. `Sentry.captureException(e)` `e.toString()` ile
  /// `value` alanına PII'yi dolaylı olarak yazabilir (örn
  /// `FormatException("Invalid date 2020-01-15")` → value: `Invalid date 2020-01-15`).
  /// Stack trace dosya yolu vs. teknik bilgi; scrub etmiyoruz.
  SentryException _scrubException(SentryException ex) {
    return SentryException(
      type: ex.type == null ? null : redactText(ex.type!),
      value: ex.value == null ? null : redactText(ex.value!),
      module: ex.module,
      stackTrace: ex.stackTrace,
      mechanism: ex.mechanism,
      threadId: ex.threadId,
      throwable: ex.throwable,
    );
  }

  /// `SentryUser` tüm PII alanları sansürlenir. Anonim bir id placeholder
  /// (`<REDACTED>`) bırakılır — SDK `SentryUser()` boş constructor'ı assert
  /// ile reddediyor, bu yüzden en az bir alan dolmalı. Bu placeholder
  /// kullanıcıyı tanımlayamaz; sadece "user objesi vardı" sinyalidir.
  SentryUser? _scrubUser(SentryUser? user) {
    if (user == null) return null;
    return SentryUser(id: '<REDACTED>');
  }

  Map<String, Object?>? _scrubMap(Map<String, Object?>? input) {
    if (input == null) return null;
    final out = <String, Object?>{};
    for (final entry in input.entries) {
      if (!allowedKeys.contains(entry.key)) {
        out[entry.key] = '<REDACTED>';
        continue;
      }
      out[entry.key] = _validateAllowedValue(entry.key, entry.value);
    }
    return out;
  }

  /// Allowlist'teki her anahtar için hem tip hem değer şeması uygular. Bir
  /// anahtarın allowlist'te olması tek başına değerinin güvenli olduğu anlamına
  /// gelmez: örneğin `durationMs: 99` yanlış kullanımda finansal tutar olabilir.
  Object? _validateAllowedValue(String key, Object? value) => switch (key) {
    'endpoint' => _scrubEndpoint(value),
    'httpStatus' => _boundedInt(value, min: 100, max: 599),
    'retryCount' => _boundedInt(value, min: 0, max: 10),
    'durationMs' => _boundedInt(value, min: 0, max: 300000),
    'backendOk' => value is bool ? value : '<REDACTED>',
    'method' => _httpMethod(value),
    'os' => _oneOf(value, const {'ios', 'android'}),
    'os_version' => _matches(value, RegExp(r'^\d{1,2}(?:\.\d{1,2})?$')),
    'app_version' ||
    'appVersion' => _matches(value, RegExp(r'^\d+\.\d+\.\d+\+\d+$')),
    'errorType' ||
    'feature' ||
    'action' ||
    'category' ||
    'platform' ||
    'context' ||
    'level' ||
    'type' => _matches(value, RegExp(r'^[A-Za-z][A-Za-z0-9_.-]{0,80}$')),
    _ => '<REDACTED>',
  };

  Object _boundedInt(Object? value, {required int min, required int max}) {
    final number = switch (value) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };
    return number != null && number >= min && number <= max
        ? number
        : '<REDACTED>';
  }

  Object _httpMethod(Object? value) =>
      _oneOf(value, const {'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'});

  Object _oneOf(Object? value, Set<String> allowed) =>
      value is String && allowed.contains(value) ? value : '<REDACTED>';

  Object _matches(Object? value, RegExp pattern) =>
      value is String && pattern.hasMatch(value) ? value : '<REDACTED>';

  /// `endpoint` allowlist anahtarı için path-only normalize ve statik endpoint
  /// şeması:
  /// - Query (`?...`) ve fragment (`#...`) tamamen kesilir.
  /// - Absolute URL ise scheme/host atılır, sadece path döner.
  /// - String olmayan değer için `<REDACTED>` (tip uyumsuzluğu zaten bug).
  Object? _scrubEndpoint(Object? value) {
    if (value is! String) return '<REDACTED>';
    final withoutFragment = value.split('#').first;
    final withoutQuery = withoutFragment.split('?').first;
    final uri = Uri.tryParse(withoutQuery);
    if (uri != null && (uri.hasScheme || uri.hasAuthority)) {
      return _validateEndpointPath(uri.path.isEmpty ? '/' : uri.path);
    }
    return _validateEndpointPath(withoutQuery);
  }

  Object _validateEndpointPath(String path) {
    if (!path.startsWith('/')) return '<REDACTED>';
    final segments = path.split('/').where((part) => part.isNotEmpty);
    final isSafe = segments.every(
      (segment) =>
          RegExp(r'^v\d+$').hasMatch(segment) ||
          RegExp(r'^[a-z-]+$').hasMatch(segment),
    );
    return isSafe ? path : '<REDACTED>';
  }

  String _scrubBreadcrumbMessage(String message) {
    final isAllowed = allowedMessagePrefixes.any(message.startsWith);
    if (!isAllowed) return '<REDACTED>';
    // Allowlist prefix ile başlasa bile ek serbest metin redaksiyona tabi.
    // Örn: 'what_if.calculated: BTC 2020-01-15' → 'what_if.calculated: <SYMBOL> <DATE>'
    return redactText(message);
  }

  Contexts _scrubContexts(Contexts contexts) {
    // SDK'nin typed context nesneleri cihaz adı/modeli, device-app hash, view
    // adı, raw user-agent, URL veya üçüncü taraf eklenti alanı taşıyabilir.
    // Bunları field bazında eksiksiz scrub edeceğimizi varsaymak güvenli değildir;
    // yalnızca kendi şemalı custom context'imiz korunur, diğer her şey drop edilir.
    final scrubbed = Contexts();
    contexts.forEach((key, value) {
      if (key == 'app_telemetry' && value is Map<String, Object?>) {
        scrubbed[key] = _scrubMap(value);
        return;
      }
      scrubbed[key] = null;
    });
    return scrubbed;
  }

  /// SDK `copyWith` semantiği: `null` ⇒ "değiştirme, eski değeri koru" anlamına
  /// gelir (`queryString ?? this.queryString`). Bu nedenle `copyWith` ile
  /// `null` geçmek query/body/cookie temizliği SAĞLAMAZ. Bunun yerine
  /// constructor'ı doğrudan çağırarak temiz bir `SentryRequest` üretiriz.
  SentryRequest _scrubRequest(SentryRequest request) {
    final url = request.url;
    return SentryRequest(
      url: url == null ? null : _scrubUrl(url),
      method: request.method,
      // Body/query/cookie tamamen yutulur — finansal payload sızıntısını engelle.
      queryString: null,
      cookies: null,
      data: null,
      fragment: null,
      apiTarget: null,
      env: null,
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
  };

  String _scrubUrl(String url) {
    // URL'yi path-only endpoint şemasına indirger. UUID dışındaki sayısal veya
    // serbest path segmentleri de kullanıcı/hesap identifier'ı olabilir;
    // yalnız statik API path'i saklanır.
    final withoutFragment = url.split('#').first;
    final withoutQuery = withoutFragment.split('?').first;
    final uri = Uri.tryParse(withoutQuery);
    final path = uri != null && (uri.hasScheme || uri.hasAuthority)
        ? uri.path
        : withoutQuery;
    final sanitized = _validateEndpointPath(path.isEmpty ? '/' : path);
    return sanitized is String ? sanitized : '<REDACTED>';
  }
}
