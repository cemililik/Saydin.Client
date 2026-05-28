import 'dart:async';

/// Uygulama yaşam döngüsü olaylarını feature'lar arası publish/subscribe ile
/// iletmek için kullanılan broadcast stream'i.
///
/// Önceki tasarım: `lib/features/account/...` doğrudan `lib/app.dart` global
/// key'ini import ediyordu — feature → app yönünde Clean Architecture sözleşmesini
/// kıran cross-layer coupling. Bu module ile feature'lar yalnızca [requestReset]
/// yayar; root widget (`AppHome`) [resetStream]'i dinleyip kendi
/// `restartFromOnboarding` metodunu çağırır.
///
/// Test izolasyonu: DI'da [AppLifecycleEvents] LazySingleton; testlerde fake
/// edilip stream akışı kontrol edilebilir.
class AppLifecycleEvents {
  AppLifecycleEvents();

  final _resetController = StreamController<void>.broadcast();

  /// Hesap silme / oturum reset gibi durumlarda root widget'ın onboarding'e
  /// dönmesini tetiklemek için yayınlanan stream.
  Stream<void> get resetStream => _resetController.stream;

  /// Tüm dinleyicilere reset event'i yayar. Idempotent — birden fazla çağrı
  /// bir o kadar event üretir; root widget zaten son state'i tekrar okumaktan
  /// zarar görmez (`AppHome.restartFromOnboarding` `setState` ile loading
  /// state'ine düşer + repository'yi tekrar sorgular).
  void requestReset() {
    _resetController.add(null);
  }

  Future<void> dispose() async {
    await _resetController.close();
  }
}
