import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// Informational English translation of the KVKK (Turkish Personal Data
/// Protection Law) disclosure. The legally binding text is the Turkish
/// version; this translation is provided for international users only.
final LegalDocument kvkkDisclosureEn = LegalDocument(
  type: LegalDocumentType.kvkkDisclosure,
  title: 'KVKK Disclosure (Turkey PDPA)',
  lastUpdated: _lastUpdated,
  sections: const [
    LegalSection(
      heading: '1. Data Controller',
      body:
          'Under Turkey\'s Personal Data Protection Law No. 6698 ("KVKK"), '
          'your personal data is processed by Saydın ("Data Controller") '
          'for the purposes described below and within the limits permitted '
          'by law.\n\n'
          'Contact: iletisim@saydin.app',
    ),
    LegalSection(
      heading: '2. Personal Data Processed',
      body:
          'When you use Saydın, the following data is processed:\n\n'
          '• Device identifier (anonymous UUID — only for usage quota and '
          'duplicate detection)\n'
          '• Technical device information (operating system version, app '
          'version, language preference)\n'
          '• In-app preferences (theme, language)\n'
          '• Locally stored scenarios (calculations you save)\n'
          '• Error reports (via Sentry — personal data is scrubbed)\n\n'
          'Direct identity information such as name, surname, email, phone, '
          'or national ID number is NOT collected.',
    ),
    LegalSection(
      heading: '3. Processing Purposes',
      body:
          'Your personal data is processed for the following purposes:\n\n'
          '• Providing and maintaining the app\'s services\n'
          '• Storing user preferences\n'
          '• Tracking free-plan usage quota\n'
          '• Error detection and debugging\n'
          '• Fulfilling legal obligations',
    ),
    LegalSection(
      heading: '4. Data Transfer',
      body:
          'Your personal data is shared with the following third parties:\n\n'
          '• Sentry (error tracking — based in the USA; personal data is '
          'sent only in scrubbed form)\n'
          '• Apple / Google (app distribution and push notification '
          'infrastructure)\n\n'
          'International transfer is performed under KVKK Article 9, '
          'either with explicit consent or where permitted by law.',
    ),
    LegalSection(
      heading: '5. Retention Period',
      body:
          'Your local data (preferences, scenarios) is stored only on your '
          'device and is deleted when you uninstall the app. When you use '
          'the account-deletion flow, all your local data is deleted '
          'immediately. Error reports are retained by Sentry for 90 days.',
    ),
    LegalSection(
      heading: '6. Rights under KVKK Article 11',
      body:
          'Under KVKK Article 11, you have the following rights:\n\n'
          '• To learn whether your personal data is being processed\n'
          '• To request information if processed\n'
          '• To learn the purpose and whether the data is used in accordance '
          'with that purpose\n'
          '• To know the parties to whom data is transferred domestically '
          'or abroad\n'
          '• To request correction if processed incompletely or incorrectly\n'
          '• To request erasure or destruction\n'
          '• To object to results that disadvantage you arising from analysis '
          'by automated systems\n'
          '• To claim damages caused by unlawful processing\n\n'
          'To exercise your rights, contact iletisim@saydin.app or use the '
          '"Delete My Account" flow inside the app.',
    ),
    LegalSection(
      heading: '7. Application & Contact',
      body:
          'Under KVKK Article 13, you may submit your requests in writing '
          'to iletisim@saydin.app. Your requests will be answered within '
          '30 days at the latest.',
    ),
  ],
);

final DateTime _lastUpdated = DateTime.utc(2026, 5, 27);
