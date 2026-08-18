import 'package:flutter/material.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/core/error/error_reporter.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart';
import 'package:saydin/features/settings/domain/usecases/reset_local_preferences.dart';

class ResetPreferencesTile extends StatefulWidget {
  const ResetPreferencesTile({super.key});

  @override
  State<ResetPreferencesTile> createState() => _ResetPreferencesTileState();
}

class _ResetPreferencesTileState extends State<ResetPreferencesTile> {
  bool _isResetting = false;

  Future<void> _requestReset() async {
    if (_isResetting) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ResetPreferencesConfirmationSheet(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isResetting = true);
    try {
      await sl<ResetLocalPreferences>()();
    } catch (error, stackTrace) {
      // Telemetri hiçbir zaman kullanıcıya gösterilecek hata geri bildirimini
      // engellememeli.
      try {
        await sl<ErrorReporter>().report(
          error,
          stackTrace,
          context: 'settings_reset_local_preferences',
        );
      } catch (_) {
        // Best effort observability.
      }
      if (!mounted) return;
      setState(() => _isResetting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Semantics(
              liveRegion: true,
              child: Text(context.l10n.resetPreferencesFailed),
            ),
          ),
        );
      return;
    }

    if (mounted) {
      setState(() => _isResetting = false);
      // Provider ağacını yeniden kurmak açık form ve hesaplama state'lerini de
      // temizler. Tamamlanma işareti use case tarafından kaldırıldığı için yeni
      // OnboardingCubit ilk tanıtım ekranını yeniden gösterir.
      sl<AppLifecycleEvents>().requestReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      key: const Key('reset-preferences-tile'),
      leading: _isResetting
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.restart_alt_rounded, color: colors.primary),
      title: Text(context.l10n.resetPreferencesTitle),
      subtitle: Text(context.l10n.resetPreferencesSubtitle),
      trailing: const Icon(Icons.chevron_right),
      enabled: !_isResetting,
      onTap: _requestReset,
    );
  }
}

class _ResetPreferencesConfirmationSheet extends StatelessWidget {
  const _ResetPreferencesConfirmationSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: const Icon(Icons.restart_alt_rounded, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.resetPreferencesConfirmTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.resetPreferencesConfirmBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(l10n.resetPreferencesAction),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
