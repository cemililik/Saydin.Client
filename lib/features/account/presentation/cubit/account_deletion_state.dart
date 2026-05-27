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

/// Hesap silme tamamen başarılı: hem yerel veri silindi hem backend talebi
/// kabul edildi (ya da backend uygun şekilde — 404/501 — toleranslı şekilde
/// geçildi).
class AccountDeletionSuccess extends AccountDeletionState {
  const AccountDeletionSuccess();
}

/// Yerel veri silindi ama backend silme talebi gönderilemedi (network hatası,
/// 5xx vb.). UI kullanıcıya "verileriniz cihazdan silindi ama sunucu talebi
/// gönderilemedi, iletisim@saydin.app üzerinden takip edin" mesajı göstermelidir.
/// Backend'in eventually consistent veri tutması KVKK uyumsuzluğu yaratır.
class AccountDeletionPartialSuccess extends AccountDeletionState {
  const AccountDeletionPartialSuccess();
}

/// Yerel veri silme başarısız oldu (genelde storage I/O). Kullanıcı tekrar
/// denemeli — hiçbir kalıcı değişiklik garanti edilemez.
class AccountDeletionFailure extends AccountDeletionState {
  const AccountDeletionFailure(this.error);

  final Object error;

  @override
  List<Object?> get props => [error];
}
