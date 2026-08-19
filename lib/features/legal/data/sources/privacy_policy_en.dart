import 'package:saydin/features/legal/domain/entities/legal_document.dart';

/// English draft aligned with the app's current technical data flows.
///
/// This is not an approved publication copy. Do not submit it to an app store
/// until the controller's legal identity/address, lawful grounds, recipient
/// and country list, transfer mechanism, and retention/deletion periods have
/// completed `docs/legal/legal-release-signoff.md` and received legal/DPO
/// approval.
final LegalDocument privacyPolicyEn = LegalDocument(
  type: LegalDocumentType.privacyPolicy,
  title: 'Privacy Policy — Publication Draft',
  lastUpdated: _lastUpdated,
  sections: const [
    LegalSection(
      heading: '1. Status and Scope',
      body:
          'This draft describes data flows observable in the current Saydın '
          'mobile client; it is not an approved final policy. The app must '
          'not be published until the controller\'s legal identity and '
          'address, processing grounds, service providers, transfer '
          'locations, and actual retention periods have been verified.',
    ),
    LegalSection(
      heading: '2. Data Categories Processed',
      body:
          'The app and service infrastructure process the following data:\n\n'
          '• A persistent, pseudonymous device identifier attached to every '
          'API request for quota and duplicate detection. It is not '
          'anonymous data.\n'
          '• Technical data such as operating system and minimized version, '
          'app version, and the selected or system language.\n'
          '• Calculation inputs: asset symbol and name, amount, amount type, '
          'date range, period, inflation choice, and comparison or portfolio '
          'components.\n'
          '• Scenarios you choose to save: the inputs above, scenario type, '
          'server identifier, creation time, and scenario-specific extra '
          'fields.\n'
          '• On-device preferences: theme, language, favorite symbols, and '
          'onboarding status; plus the displayed legal bundle version/hash, '
          'document identifiers, display language and UTC time, and whether '
          'the notice was only seen or optionally checked by the user.\n'
          '• Sentry error/crash telemetry is enabled in store builds and is '
          'disabled in local/test builds that have no DSN. Because Sentry '
          'starts before the app UI and legal notice, startup and notice '
          'display/recording failures may also be processed. Technical action '
          'breadcrumbs and app/OS version may be processed. Screenshot '
          'sending, session replay, automatic session tracking, and performance tracing are '
          'disabled. Dart error events are filtered before sending; that is '
          'not a verified guarantee for native crash envelopes.',
    ),
    LegalSection(
      heading: '3. Why the Data Is Used',
      body:
          'Data is processed to provide financial calculations and saved '
          'scenarios, remember preferences, manage free-usage quota and '
          'duplicate operations, protect the service, and diagnose technical '
          'startup/runtime errors in builds where Sentry is enabled. The '
          'client code contains no '
          'advertising, behavioral-marketing, or data-sale integration.',
    ),
    LegalSection(
      heading: '4. On-Device and Server Processing',
      body:
          'Theme, language, favorites, onboarding/legal-text records, and '
          'temporary share images are processed on the device. The device '
          'identifier is held in secure local storage. Calculation inputs '
          'are sent to the service API. Scenarios you save are sent to the '
          'API server and later retrieved for display on your devices. Saved '
          'scenarios therefore cannot be described as on-device only. When '
          'you choose to share a result card, the financial summary and PNG '
          'are handed to the system share sheet. The messaging, social, file, '
          'or photo app you select becomes a separate recipient and applies '
          'its own privacy terms; review the preview and recipient before '
          'sending.',
    ),
    LegalSection(
      heading: '5. Service Providers and Transfers',
      body:
          'Data may be processed by the hosting/network providers operating '
          'the Saydın API infrastructure. Store release builds cannot be '
          'created without SENTRY_DSN, so Sentry processes technical '
          'telemetry in those builds; it is disabled in local/test builds '
          'without a DSN. Apple App Store '
          'and Google Play may separately process data under their own '
          'policies during app distribution. The exact recipient groups, '
          'processing countries, and any international-transfer mechanism '
          'must be verified and added to the final text before publication.',
    ),
    LegalSection(
      heading: '6. Retention and Deletion',
      body:
          'Local preferences, favorites, and onboarding records remain until '
          'the app storage is cleared; the device identifier remains until '
          'secure local storage is cleared. Removal of the app alone is not '
          'guaranteed to remove iOS Keychain data. Scenarios can be deleted '
          'individually in the app. The account-deletion flow first sends a '
          'server deletion request and clears local data only after a 200 or '
          '204 response is verified. If the server request cannot be verified, '
          'local data and the device identifier are retained, an error is '
          'shown, and the request can be retried with the same identity. The '
          'verified server, backup, and Sentry retention/deletion periods '
          'must be added before publication.',
    ),
    LegalSection(
      heading: '7. Security and Data Minimization',
      body:
          'API connections use HTTPS. The device identifier is stored '
          'through iOS Keychain or Android encrypted storage. The Sentry '
          'configuration disables default personal-data, screenshot sending, '
          'session replay, automatic session tracking, and performance tracing. It filters '
          'request bodies and known financial-data patterns in Dart error '
          'events. Native crash envelopes require separate production-like '
          'RC inspection. Filtering is an additional safeguard, not a '
          'guarantee of flawless or complete anonymization.',
    ),
    LegalSection(
      heading: '8. Direct Identifiers and Children',
      body:
          'The current app interface has no field requesting your name, '
          'email, phone number, or government identifier, and it requests no '
          'precise-location or contacts-reading permission. If you choose to '
          'save a result card to Photos, iOS may request add-only photo '
          'library permission; it does not grant access to read existing '
          'photos. The app is not designed for '
          'children under 13.',
    ),
    LegalSection(
      heading: '9. Rights, Changes, and Contact',
      body:
          'You can delete saved scenarios individually and start the account '
          'deletion flow in the app. For privacy questions and technical '
          'support, email iletisim@saydin.app. Formal data-controller request '
          'channels must be published together with the controller\'s legal '
          'name and service address before release. Material policy changes '
          'should be announced in the app and reflected in the last-updated '
          'date.',
    ),
  ],
);

final DateTime _lastUpdated = DateTime.utc(2026, 8, 18);
