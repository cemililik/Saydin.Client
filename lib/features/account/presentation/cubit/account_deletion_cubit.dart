import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_state.dart';

/// Hesap silme akışını yöneten Cubit.
///
/// Akış:
///   1) Kullanıcı onay yazısını ("SİL"/"DELETE") tamamlayıp silme tetikler.
///   2) [AccountDataRepository.requestBackendDeletion] backend'e best-effort
///      delete isteği atar (404/501 toleranslı).
///   3) [AccountDataRepository.wipeLocalData] yerel veri (`SharedPreferences`,
///      `SecureStorage`, paylaşım PNG cache, device ID in-memory cache) siler.
///   4) State machine'in nihai çıktısı:
///      - Backend OK + wipe OK  → [AccountDeletionSuccess]
///      - Backend FAIL + wipe OK → [AccountDeletionPartialSuccess] (UI
///        kullanıcıya "sunucu talebi gönderilemedi" uyarısı verir)
///      - Wipe FAIL              → [AccountDeletionFailure] (kalıcı garanti yok)
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

  Future<void> requestDeletion() async {
    if (state is AccountDeletionInProgress) return;
    emit(const AccountDeletionInProgress());

    // 1) Backend best-effort (yerel silme her zaman kazanır).
    // Repository sözleşmesi throw etmemeyi garanti eder; yine de
    // implementation değişikliklerine karşı defansif try/catch koyarız —
    // beklenmedik bir exception yerel wipe'ı engellememeli.
    var backendOk = false;
    try {
      backendOk = await _repository.requestBackendDeletion();
    } catch (e, st) {
      await _reporter.report(
        e,
        st,
        context: 'account_deletion_backend_request',
      );
    }
    await _reporter.recordAction(
      'settings.account_delete_requested',
      category: 'settings',
      data: {'action': 'account_delete_requested', 'backendOk': backendOk},
    );

    // 2) Yerel veriyi sil — burası başarısız olursa kullanıcıya bildir
    try {
      await _repository.wipeLocalData();
      await _reporter.recordAction(
        'settings.account_deleted',
        category: 'settings',
        data: {'action': 'account_deleted', 'backendOk': backendOk},
      );
      // Yerel veri silindi (full ya da partial backend) — root widget'a
      // onboarding'e geri dönmesini bildiren reset event'ini yay.
      _lifecycleEvents.requestReset();
      emit(
        backendOk
            ? const AccountDeletionSuccess()
            : const AccountDeletionPartialSuccess(),
      );
    } catch (e, st) {
      await _reporter.report(e, st, context: 'account_deletion');
      emit(AccountDeletionFailure(e));
    }
  }

  void reset() {
    emit(const AccountDeletionIdle());
  }
}
