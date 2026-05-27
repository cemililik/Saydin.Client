import 'package:equatable/equatable.dart';

sealed class AccountDeletionState extends Equatable {
  const AccountDeletionState();

  @override
  List<Object?> get props => const [];
}

class AccountDeletionIdle extends AccountDeletionState {
  const AccountDeletionIdle();
}

class AccountDeletionInProgress extends AccountDeletionState {
  const AccountDeletionInProgress();
}

class AccountDeletionSuccess extends AccountDeletionState {
  const AccountDeletionSuccess();
}

class AccountDeletionFailure extends AccountDeletionState {
  const AccountDeletionFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
