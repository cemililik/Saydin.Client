import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_state.dart';

/// Hesap silme akışını yöneten Cubit.
///
/// Akış:
///   1) Kullanıcı onay yazısını ("SİL"/"DELETE") tamamlayıp silme tetikler.
///   2) [AccountDataRepository.requestBackendDeletion] backend'in silmeyi
///      tamamladığını doğrular. Başarısızsa yerel veri ve device identity
///      korunur; kullanıcı aynı kimlikle tekrar deneyebilir.
///   3) Yalnızca backend kabulünden sonra [AccountDataRepository.wipeLocalData]
///      yerel veriyi (`SharedPreferences`, `SecureStorage`, paylaşım PNG cache,
///      device ID in-memory cache) siler.
///   4) State machine'in nihai çıktısı:
///      - Backend OK + wipe OK  → [AccountDeletionSuccess]
///      - Backend FAIL           → [AccountDeletionFailure] (local wipe yok)
///      - Wipe FAIL              → [AccountDeletionLocalCleanupPending]
///        (backend tekrar edilmeden local cleanup retry)
class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  AccountDeletionCubit({
    required AccountDataRepository repository,
    required ErrorReporter reporter,
    required AppLifecycleEvents lifecycleEvents,
  }) : _repository = repository,
       _reporter = reporter,
       _lifecycleEvents = lifecycleEvents,
       super(const AccountDeletionIdle());

  final AccountDataRepository _repository;
  final ErrorReporter _reporter;
  final AppLifecycleEvents _lifecycleEvents;
  bool _backendDeletionConfirmedInSession = false;
  bool _cleanupMarkerPersistedInSession = false;

  Future<void> requestDeletion() async {
    if (state is AccountDeletionInProgress) return;
    emit(const AccountDeletionInProgress());

    // Önce daha eski bir denemeden kalmış backend-confirmed cleanup marker'ını
    // oku. Marker varsa DELETE'i tekrar etmek yerine yalnız local cleanup
    // sürdürülür; bu, remote başarı + local I/O failure + app restart zincirini
    // idempotent yapar.
    try {
      final hasPersistedMarker = await _repository.hasPendingLocalCleanup();
      if (hasPersistedMarker) {
        _backendDeletionConfirmedInSession = true;
        _cleanupMarkerPersistedInSession = true;
      }
    } catch (e, st) {
      await _reportBestEffort(e, st, context: 'account_deletion_phase_read');
      emit(AccountDeletionFailure(e));
      return;
    }

    // 1) Pending cleanup yoksa önce backend kabulü. Repository sözleşmesi
    // throw etmemeyi garanti
    // eder; yine de implementation değişikliğine karşı defansif davranırız.
    // Backend sonucu belirsiz/başarısızsa local wipe'a KESİNLİKLE geçmeyiz:
    // eski X-Device-ID silinirse kullanıcı aynı hesabın silinmesini yeniden
    // talep edemez.
    var backendOk = _backendDeletionConfirmedInSession;
    if (!backendOk) {
      try {
        backendOk = await _repository.requestBackendDeletion();
      } catch (e, st) {
        await _reportBestEffort(
          e,
          st,
          context: 'account_deletion_backend_request',
        );
      }
      if (backendOk) {
        _backendDeletionConfirmedInSession = true;
      }
    }
    await _recordActionBestEffort(
      'settings.account_delete_requested',
      category: 'settings',
      data: {'action': 'account_delete_requested', 'backendOk': backendOk},
    );

    if (!backendOk) {
      emit(const AccountDeletionFailure(AccountDeletionBackendException()));
      return;
    }

    // Destructive cleanup başlamadan ÖNCE backend-confirmed fazı durable
    // olmalıdır. Marker yazılamazken wipe'a geçmek; device ID'yi kaybedip
    // process restart sonrası DELETE retry'ını imkânsızlaştırabilirdi.
    if (!_cleanupMarkerPersistedInSession) {
      try {
        await _repository.markLocalCleanupPending();
        _cleanupMarkerPersistedInSession = true;
      } catch (e, st) {
        await _reportBestEffort(e, st, context: 'account_deletion_phase_write');
        emit(AccountDeletionLocalCleanupPending(e));
        return;
      }
    }

    // 2) Backend 2xx onayından sonra yerel veriyi sil.
    try {
      await _repository.wipeLocalData();
      // Wipe başarılı — Sentry scope'undaki tüm breadcrumb/user/tag bilgisini
      // temizle. Bu, silinen cihazın eski device-ID'siyle ilişkilendirilmiş
      // breadcrumb'ların sonraki crash event'lerine eklenmesini önler
      // (KVKK Madde 11 silme hakkının observability tarafındaki karşılığı).
      // Önce clear, sonra tek bir teknik telemetri breadcrumb'ı — bu yeni
      // breadcrumb fresh scope'a yazılır.
      await _reporter.clearScope();
      // Marker ancak privacy cleanup'ın zorunlu adımları tamamlanınca silinir.
      // clearScope/marker-clear düşerse retry yine backend'e dönmeden cleanup'ı
      // idempotent biçimde sürdürür.
      await _repository.clearPendingLocalCleanup();
      _cleanupMarkerPersistedInSession = false;
      _backendDeletionConfirmedInSession = false;
      // Yerel veri silindi — root widget'a onboarding'e geri dönmesini
      // bildiren reset event'ini yay.
      _lifecycleEvents.requestReset();
      emit(const AccountDeletionSuccess());
      // Breadcrumb yalnız telemetridir; başarısızlığı silme sonucunu geriye
      // çeviremez veya state'i InProgress'te bırakamaz.
      await _recordActionBestEffort(
        'settings.account_deleted',
        category: 'settings',
        data: {'action': 'account_deleted', 'backendOk': backendOk},
      );
    } catch (e, st) {
      await _reportBestEffort(e, st, context: 'account_deletion');
      emit(AccountDeletionLocalCleanupPending(e));
    }
  }

  Future<void> _recordActionBestEffort(
    String action, {
    required String category,
    required Map<String, Object?> data,
  }) async {
    try {
      await _reporter.recordAction(action, category: category, data: data);
    } catch (_) {
      // Telemetry hiçbir privacy state-machine transition'ını bloke edemez.
    }
  }

  Future<void> _reportBestEffort(
    Object error,
    StackTrace stackTrace, {
    required String context,
  }) async {
    try {
      await _reporter.report(error, stackTrace, context: context);
    } catch (_) {
      // İkincil reporter hatası asıl terminal state'in yayınlanmasını engellemez.
    }
  }

  void reset() {
    emit(const AccountDeletionIdle());
  }
}

/// Backend silme talebinin tamamlandığı doğrulanmadı. Bu hata state'i, kullanıcının
/// cihaz kimliği ve yerel verilerinin kasıtlı olarak korunduğunu belirtir;
/// tekrar denemek güvenlidir.
class AccountDeletionBackendException implements Exception {
  const AccountDeletionBackendException();

  @override
  String toString() => 'AccountDeletionBackendException';
}
