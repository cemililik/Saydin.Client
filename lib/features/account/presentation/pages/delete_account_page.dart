import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/utils/turkish_text.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_cubit.dart';
import 'package:saydin/features/account/presentation/cubit/account_deletion_state.dart';

/// Hesap silme onay sayfası.
///
/// Kullanıcı bir confirmation phrase (locale'a göre "SİL" veya "DELETE")
/// yazmadan silme butonu aktif olmaz — kazara silmeyi engeller. Başarılı
/// silme sonrası tüm route stack temizlenir ve [appHomeKey] üzerinden
/// `AppHome` state'i sıfırlanarak kullanıcı onboarding'e geri döner.
class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountDeletionCubit>(),
      child: const _DeleteAccountView(),
    );
  }
}

class _DeleteAccountView extends StatefulWidget {
  const _DeleteAccountView();

  @override
  State<_DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<_DeleteAccountView> {
  final _controller = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final confirmWord = l10n.deleteAccountConfirmWord;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: BlocConsumer<AccountDeletionCubit, AccountDeletionState>(
        listener: (context, state) {
          switch (state) {
            case AccountDeletionSuccess():
              _onDeletionSuccess(context, message: l10n.deleteAccountSuccess);
            case AccountDeletionPartialSuccess():
              _onDeletionSuccess(
                context,
                message: l10n.deleteAccountPartialSuccess,
                durationSeconds: 8,
              );
            case AccountDeletionFailure():
              _showFailureSnackbar(context, l10n.deleteAccountFailed);
            case AccountDeletionIdle() || AccountDeletionInProgress():
              break;
          }
        },
        builder: (context, state) {
          final inProgress = state is AccountDeletionInProgress;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WarningCard(theme: theme, text: l10n.deleteAccountWarning),
                  const SizedBox(height: 20),
                  Text(
                    l10n.deleteAccountConfirmHint(confirmWord),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    enabled: !inProgress,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: confirmWord,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Türkçe-aware compare: `'sil'.toUpperCase()` Dart'ta
                      // `'SIL'` (dotless I) döner, `confirmWord` ARB'de `'SİL'`
                      // (dotted İ). `eqIgnoreCaseTr` doğru normalizasyonu yapar.
                      final ok = eqIgnoreCaseTr(value, confirmWord);
                      if (ok != _confirmed) {
                        setState(() => _confirmed = ok);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _confirmed && !inProgress
                        ? () => context
                              .read<AccountDeletionCubit>()
                              .requestDeletion()
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: Text(
                      inProgress
                          ? l10n.deleteAccountInProgress
                          : l10n.deleteAccountConfirmButton,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onDeletionSuccess(
    BuildContext context, {
    required String message,
    int durationSeconds = 4,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: durationSeconds),
      ),
    );
    // Tüm route stack'i temizleyip root'a dön. `AppHome` zaten
    // `AppLifecycleEvents.resetStream` üzerinden cubit'in yayınladığı
    // reset event'ini dinleyip kendi onboarding state'ini sıfırlayacak.
    // Bu page artık app.dart'a doğrudan bağımlı değil.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showFailureSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.theme, required this.text});

  final ThemeData theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
