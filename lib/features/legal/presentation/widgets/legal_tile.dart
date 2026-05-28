import 'package:flutter/material.dart';
import 'package:saydin/core/di/injection.dart';
import 'package:saydin/features/legal/domain/entities/legal_document.dart';
import 'package:saydin/features/legal/domain/repositories/legal_repository.dart';
import 'package:saydin/features/legal/presentation/pages/legal_document_page.dart';

/// Settings altında yasal belgeyi açan navigasyon tile'ı. Document'i locale'a
/// göre lazy load eder.
class LegalTile extends StatelessWidget {
  const LegalTile({
    super.key,
    required this.type,
    required this.title,
    this.leading,
  });

  final LegalDocumentType type;
  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context),
    );
  }

  Future<void> _open(BuildContext context) async {
    final locale = Localizations.localeOf(context).toString();
    final document = sl<LegalRepository>().load(type, locale);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => LegalDocumentPage(document: document)),
    );
  }
}
