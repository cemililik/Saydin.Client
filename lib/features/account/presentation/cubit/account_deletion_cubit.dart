import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_state.dart';

/// Hesap silme akışını yöneten Cubit.
///
/// Akış:
///   1) Kullanıcı onay yazısını ("SİL"/"DELETE") tamamlayıp silme tetikler.
///   2) [requestDeletion] backend'e best-effort delete isteği atar
///      (404/501 toleranslı).
///   3) Yerel veri (`SharedPreferences` + `SecureStorage`) silinir.
///   4) [AccountDeletionSuccess] emit edilir; UI tarafı onboarding'e döner.
class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  AccountDeletionCubit({
    required AccountDataRepository repository,
    required ErrorReporter reporter,
  }) : _repository = repository,
       _reporter = reporter,
       super(const AccountDeletionIdle());

  final AccountDataRepository _repository;
  final ErrorReporter _reporter;

  Future<void> requestDeletion() async {
    if (state is AccountDeletionInProgress) return;
    emit(const AccountDeletionInProgress());

    // 1) Backend best-effort (yerel silme her zaman kazanır)
    final backendOk = await _repository.requestBackendDeletion();
    await _reporter.recordAction(
      'settings.account_delete_requested',
      category: 'settings',
      data: {
        'action': 'account_delete_requested',
        'httpStatus': backendOk ? 200 : 500,
      },
    );

    // 2) Yerel veriyi sil — burası başarısız olursa kullanıcıya bildir
    try {
      await _repository.wipeLocalData();
      await _reporter.recordAction(
        'settings.account_deleted',
        category: 'settings',
        data: const {'action': 'account_deleted'},
      );
      emit(const AccountDeletionSuccess());
    } catch (e, st) {
      await _reporter.report(e, st, context: 'account_deletion');
      emit(AccountDeletionFailure(e));
    }
  }

  void reset() {
    emit(const AccountDeletionIdle());
  }
}
