import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Onboarding akışının durumu.
enum OnboardingStatus {
  /// Henüz `SharedPreferences`'tan okunmadı — boş/splash ekran gösterilir.
  unknown,

  /// Tamamlanmamış — onboarding sayfaları gösterilir.
  pending,

  /// Tamamlanmış — ana uygulamaya geçilir.
  completed,
}

/// Onboarding tamamlanma durumunu yönetir.
///
/// Önceden `_AppHome` `StatefulWidget` içinde ad-hoc `bool? + setState` ve
/// elle yönetilen bir `StreamSubscription` ile tutuluyordu (F-12-09). Cubit'e
/// taşınınca: durum test edilebilir hale gelir, hesap-silme reset aboneliği
/// `close()` ile düzgün temizlenir ve ileride "tanıtımı tekrar izle" (F-12-02)
/// gibi akışlar [restart] ile trivial olur.
class OnboardingCubit extends Cubit<OnboardingStatus> {
  final OnboardingRepository _repository;
  StreamSubscription<void>? _resetSubscription;

  OnboardingCubit(this._repository, AppLifecycleEvents lifecycleEvents)
    : super(OnboardingStatus.unknown) {
    // Hesap silme sonrası `AccountDeletionCubit` reset event yayar; dinleyip
    // onboarding'i baştan başlatırız. Feature → app yönündeki bağı keser
    // (publish/subscribe), abonelik [close] içinde iptal edilir.
    _resetSubscription = lifecycleEvents.resetStream.listen((_) => restart());
  }

  /// `SharedPreferences`'tan onboarding durumunu okur (uygulama açılışında).
  Future<void> load() async {
    final completed = await _repository.isOnboardingCompleted();
    emit(completed ? OnboardingStatus.completed : OnboardingStatus.pending);
  }

  /// Onboarding tamamlandı — kalıcı kaydet ve ana uygulamaya geç.
  Future<void> complete() async {
    await _repository.completeOnboarding();
    emit(OnboardingStatus.completed);
  }

  /// Onboarding'i baştan başlatır (hesap silme / "tekrar izle"): durumu
  /// `unknown`'a alıp depodan yeniden okur.
  Future<void> restart() async {
    emit(OnboardingStatus.unknown);
    await load();
  }

  @override
  Future<void> close() async {
    // Aboneliği super.close()'tan ÖNCE ve await ile iptal et: broadcast
    // resetStream'in teardown sırasında restart() (→ emit) tetiklemesini
    // garanti altına al (close sonrası emit StateError'a yol açardı).
    await _resetSubscription?.cancel();
    return super.close();
  }
}
