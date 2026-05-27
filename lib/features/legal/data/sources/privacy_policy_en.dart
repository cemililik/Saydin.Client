import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// Privacy Policy — English. Required for App Store / Google Play submission.
/// Template text; obtain legal advice before publishing.
final LegalDocument privacyPolicyEn = LegalDocument(
  type: LegalDocumentType.privacyPolicy,
  title: 'Privacy Policy',
  lastUpdated: _lastUpdated,
  sections: const [
    LegalSection(
      heading: '1. Introduction',
      body:
          'At Saydın, we value your privacy. This policy explains what data '
          'is collected when you use the app, how it is used, and how it is '
          'protected.',
    ),
    LegalSection(
      heading: '2. Data We Collect',
      body:
          '• Anonymous device identifier (UUID — for usage quota tracking)\n'
          '• Technical device info: OS, app version, language\n'
          '• Local preferences: theme, language, saved scenarios\n'
          '• Error reports (via Sentry — personal data is scrubbed)\n\n'
          'Data we do NOT collect: name, surname, email, phone, location, '
          'contacts, photos, real financial portfolio information.',
    ),
    LegalSection(
      heading: '3. How We Use Data',
      body:
          '• Providing the calculation service\n'
          '• Storing your preferences\n'
          '• Error detection and app improvement\n'
          '• Abuse detection (rate limiting)\n\n'
          'Data is not collected or shared for advertising, marketing, or '
          'sales purposes.',
    ),
    LegalSection(
      heading: '4. Third Parties',
      body:
          '• Sentry (sentry.io) — error tracking. Financial data such as '
          'dates, amounts, and symbols are sent only in scrubbed form.\n'
          '• Apple App Store / Google Play — app distribution.\n\n'
          'These services\' own privacy policies apply.',
    ),
    LegalSection(
      heading: '5. Data Retention',
      body:
          'All your local data is stored on your device. No user-specific '
          'data is kept on our servers; only anonymous usage metrics (total '
          'calculation count) are stored.\n\n'
          'When you delete your account, all local data is deleted '
          'immediately. Sentry error reports are auto-deleted within 90 '
          'days at most.',
    ),
    LegalSection(
      heading: '6. Security',
      body:
          '• All network traffic is encrypted via HTTPS (TLS 1.2+).\n'
          '• Device identifier is stored in encrypted local storage '
          '(Keychain / EncryptedSharedPreferences).\n'
          '• Screenshots are never sent in error reports.',
    ),
    LegalSection(
      heading: '7. Children\'s Privacy',
      body:
          'The app is not designed for children under 13. We do not '
          'knowingly collect data from users known to be under 13.',
    ),
    LegalSection(
      heading: '8. Policy Changes',
      body:
          'This policy may change. Material changes are announced inside '
          'the app. The last-updated date appears below.',
    ),
    LegalSection(
      heading: '9. Contact',
      body: 'For questions, please email iletisim@saydin.app.',
    ),
  ],
);

final DateTime _lastUpdated = DateTime.utc(2026, 5, 27);
