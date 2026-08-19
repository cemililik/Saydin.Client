import 'dart:async';

/// Uygulama yaşam döngüsü olaylarını feature'lar arası publish/subscribe ile
/// iletmek için kullanılan broadcast stream'i.
///
/// Önceki tasarım: `lib/features/account/...` doğrudan `lib/app.dart` global
/// key'ini import ediyordu — feature → app yönünde Clean Architecture sözleşmesini
/// kıran cross-layer coupling. Bu module ile feature'lar yalnızca [requestReset]
/// yayar; root `AppSessionResetBoundary` bütün session/user BLoC provider
/// alt-ağacını keyed olarak yeniden yaratır.
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
  /// bir o kadar event üretir; root boundary her event'te yeni bir session
  /// generation oluşturur ve provider'lar temiz storage'dan yeniden yüklenir.
  void requestReset() {
    _resetController.add(null);
  }

  Future<void> dispose() async {
    await _resetController.close();
  }
}
