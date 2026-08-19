import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// Informational English translation of the KVKK Article 10 technical draft.
///
/// The Turkish text will be authoritative only after legal/DPO approval. The
/// controller identity/address, category-specific Article 5 grounds, exact
/// recipients/countries and Article 9 transfer mechanism, retention schedule,
/// and formal request channels must complete
/// `docs/legal/legal-release-signoff.md` before publication.
final LegalDocument kvkkDisclosureEn = LegalDocument(
  type: LegalDocumentType.kvkkDisclosure,
  title: 'KVKK Disclosure — Publication Draft',
  lastUpdated: _lastUpdated,
  sections: const [
    LegalSection(
      heading: '1. Draft Status and Data Controller',
      body:
          'This is a technical-inventory draft prepared for Article 10 of '
          'Turkey\'s Personal Data Protection Law No. 6698 (KVKK); it is not '
          'an approved disclosure. The controller\'s official legal name, '
          'service address, and representative (if any) have not been '
          'verified in this repository. The app must not be published before '
          'those details are completed. Current contact for technical and '
          'privacy questions: iletisim@saydin.app.',
    ),
    LegalSection(
      heading: '2. Personal Data Categories Processed',
      body:
          '• A persistent, pseudonymous device identifier attached to every '
          'API request. This UUID is used for quota and duplicate detection '
          'and is not anonymous data.\n'
          '• Technical data such as operating system, minimized OS version, '
          'app version, and the selected or system language.\n'
          '• Financial-calculation inputs: asset symbol/name, amount and '
          'type, dates, period, inflation choice, and comparison or portfolio '
          'components.\n'
          '• Saved-scenario data: calculation inputs, scenario type, server '
          'identifier, creation time, and type-specific extra fields.\n'
          '• Theme, language, favorites, and onboarding status stored on the '
          'device; the displayed legal bundle version/hash, document IDs, '
          'display language and UTC time, and whether the notice was only '
          'seen or optionally checked by the user.\n'
          '• If the user chooses to share, the financial-result summary and '
          'PNG handed to the system share sheet; the selected destination '
          'app is a separate recipient of that content.\n'
          '• Sentry error/crash telemetry is enabled in store release builds '
          'and disabled in local/test builds without a DSN. Because the SDK '
          'starts before the app UI and legal notice, startup and notice '
          'display/recording failures may also be processed. Technical action '
          'breadcrumbs and app/OS version may be processed. Screenshot '
          'sending, session replay, automatic session tracking, and performance tracing are '
          'disabled. Dart error events are filtered; this is not a verified '
          'guarantee for native crash envelopes or absolute anonymization.\n\n'
          'The current interface has no input for name, email, phone, or '
          'government identifier, and requests no precise-location or '
          'contacts-reading permission. If the user chooses to save a result '
          'card to Photos, iOS may request add-only photo-library permission; '
          'it does not grant access to read existing photos.',
    ),
    LegalSection(
      heading: '3. Processing Purposes',
      body:
          'Data is processed to provide financial calculations and saved '
          'scenarios, remember preferences, manage free-usage quota and '
          'duplicate operations, protect the service, and diagnose technical '
          'startup/runtime errors in builds where Sentry is enabled. The current '
          'client contains no advertising, behavioral-marketing, or '
          'data-sale integration.',
    ),
    LegalSection(
      heading: '4. Collection Method and Legal Grounds',
      body:
          'Device/app technical data is collected automatically during API '
          'requests; calculation and scenario data is collected '
          'electronically through user choices in the app; local preferences '
          'through device-storage interfaces; and telemetry through the SDK '
          'in store release builds and other builds where Sentry is '
          'configured. The applicable KVKK Article 5 '
          'condition has not been selected and stated for each category by '
          'legal/DPO review. This is not final until that work is complete; '
          'a disclosure does not itself constitute explicit consent.',
    ),
    LegalSection(
      heading: '5. Recipient Groups and Transfers',
      body:
          'API data may be processed by hosting and network providers '
          'operating the Saydın service infrastructure. Store release builds '
          'cannot be created without SENTRY_DSN, so Sentry processes technical '
          'telemetry in those builds; it is disabled in local/test builds '
          'without a DSN. Apple '
          'App Store and Google Play may separately process data under their '
          'own policies during distribution. A messaging, social, file, or '
          'photo app selected by the user in the system share sheet processes '
          'the shared content under its own terms. The exact recipient groups, '
          'provider processing countries, and any international-transfer '
          'mechanism under KVKK Article 9 must be verified and added before '
          'publication.',
    ),
    LegalSection(
      heading: '6. Retention, Security, and Deletion',
      body:
          'Theme, language, favorites, and onboarding records remain until '
          'app storage is cleared; the device identifier remains until '
          'secure local storage is cleared. Removing the app alone is not '
          'guaranteed to remove iOS Keychain data. Calculation inputs are '
          'sent to the API server; saved scenarios are stored there and can '
          'be deleted individually. Account deletion sends a server request '
          'and clears local data only after a 200 or 204 response. If the server '
          'result cannot be verified, local data and the device identifier '
          'are retained, an error is shown, and the same identity can retry. '
          'The API uses HTTPS and the device '
          'identifier uses secure local storage. This text is not final until '
          'verified server, backup, and Sentry retention/deletion periods '
          'are supplied.',
    ),
    LegalSection(
      heading: '7. Rights under KVKK Article 11',
      body:
          'Under KVKK Article 11, you may ask whether your personal data is '
          'processed; request information if it is; learn the purpose and '
          'whether it is used accordingly; know third parties to whom it is '
          'transferred in Turkey or abroad; request correction of incomplete '
          'or inaccurate data; request erasure or destruction when the '
          'conditions apply and notification of those operations to third '
          'parties; object to an adverse result produced exclusively by '
          'automated analysis; and claim compensation for damage caused by '
          'unlawful processing.',
    ),
    LegalSection(
      heading: '8. Request Channels',
      body:
          'You can delete scenarios and start account deletion inside the '
          'app. iletisim@saydin.app is for privacy questions and technical '
          'support; it is not represented as the sole valid channel for all '
          'formal KVKK requests. The controller\'s written-request address, '
          'registered electronic mail (KEP) channel if available, and other '
          'valid methods must be published with the legal name before '
          'release. Valid requests are answered as soon as possible and no '
          'later than 30 days, depending on their nature.',
    ),
  ],
);

final DateTime _lastUpdated = DateTime.utc(2026, 8, 18);
