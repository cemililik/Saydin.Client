import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// Yasal doküman (KVKK, gizlilik politikası) okuma sayfası.
/// Salt-okunur, scrollable, `SelectableText` ile kopyalanabilir.
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMMd(locale).format(document.lastUpdated);

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SafeArea(
        child: Scrollbar(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: document.sections.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              if (index == document.sections.length) {
                return _LastUpdatedLabel(
                  text: l10n.legalLastUpdated(dateLabel),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              final section = document.sections[index];
              return _LegalSectionView(section: section);
            },
          ),
        ),
      ),
    );
  }
}

class _LegalSectionView extends StatelessWidget {
  const _LegalSectionView({required this.section});

  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          section.heading,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SelectableText(
          section.body,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
    );
  }
}

class _LastUpdatedLabel extends StatelessWidget {
  const _LastUpdatedLabel({required this.text, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(text, style: style),
    );
  }
}
