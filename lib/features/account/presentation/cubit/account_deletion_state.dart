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

/// Hesap silme tamamen başarılı: backend talebi kabul edildi ve yerel veri
/// silindi.
class AccountDeletionSuccess extends AccountDeletionState {
  const AccountDeletionSuccess();
}

/// Backend silmeyi doğruladı ancak durable phase yazımı veya cihazdaki cleanup
/// adımlarından en az biri tamamlanmadı. Kullanıcı tekrar denediğinde backend
/// DELETE tekrarlanmaz; marker yazımı ve idempotent local cleanup sürdürülür.
class AccountDeletionLocalCleanupPending extends AccountDeletionState {
  const AccountDeletionLocalCleanupPending(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}

/// Eski API tüketicileri için korunmuş durum. Backend silme talebi başarısızsa
/// artık yerel veri silinmez ve [AccountDeletionFailure] yayınlanır; bu state
/// yeni akış tarafından üretilmez.
@Deprecated(
  'Backend failure now emits AccountDeletionFailure without local wipe.',
)
class AccountDeletionPartialSuccess extends AccountDeletionState {
  const AccountDeletionPartialSuccess();
}

/// Backend sonucu doğrulanmadan önce oluşan hata veya cleanup phase bilgisinin
/// okunamadığı durum. Backend onaylı local-cleanup hataları için ayrı
/// [AccountDeletionLocalCleanupPending] kullanılır.
class AccountDeletionFailure extends AccountDeletionState {
  const AccountDeletionFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
