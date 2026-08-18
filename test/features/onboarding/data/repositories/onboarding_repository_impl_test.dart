import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPrefs prefs;
  late OnboardingRepositoryImpl repo;

  setUp(() {
    prefs = _MockPrefs();
    repo = OnboardingRepositoryImpl(prefs);
  });

  group('legal notice record', () {
    final record = LegalNoticeRecord.current(
      locale: 'tr-TR',
      recordedAtUtc: DateTime.utc(2026, 8, 18, 12),
      decision: LegalNoticeDecision.acknowledged,
    );

    test('writes document ids, hash, locale, timestamp and decision', () async {
      when(() => prefs.setString(any(), any())).thenAnswer((_) async {});

      await repo.recordLegalNotice(record);

      final encoded =
          verify(
                () => prefs.setString('legal_notice_record_v2', captureAny()),
              ).captured.single
              as String;
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      expect(json['version'], LegalAcceptanceVersion.current);
      expect(json['bundleSha256'], LegalAcceptanceVersion.bundleSha256);
      expect(json['privacyDocumentId'], isNotEmpty);
      expect(json['kvkkDocumentId'], isNotEmpty);
      expect(json['locale'], 'tr-TR');
      expect(json['recordedAtUtc'], '2026-08-18T12:00:00.000Z');
      expect(json['decision'], 'acknowledged');
    });

    test('round-trips a valid record', () async {
      when(() => prefs.getString(any())).thenAnswer(
        (_) async => jsonEncode({
          'version': record.version,
          'bundleSha256': record.bundleSha256,
          'privacyDocumentId': record.privacyDocumentId,
          'kvkkDocumentId': record.kvkkDocumentId,
          'locale': record.locale,
          'recordedAtUtc': record.recordedAtUtc.toIso8601String(),
          'decision': record.decision.name,
        }),
      );

      expect(await repo.getLegalNotice(), record);
    });

    test('malformed or legacy-only storage forces a fresh notice', () async {
      when(
        () => prefs.getString('legal_notice_record_v2'),
      ).thenAnswer((_) async => '{bad-json');
      expect(await repo.getLegalNotice(), isNull);
      verifyNever(() => prefs.getInt('legal_acceptance_version'));
    });

    test('invalid non-UTC record is rejected', () async {
      final invalid = LegalNoticeRecord(
        version: record.version,
        bundleSha256: record.bundleSha256,
        privacyDocumentId: record.privacyDocumentId,
        kvkkDocumentId: record.kvkkDocumentId,
        locale: record.locale,
        recordedAtUtc: DateTime(2026, 8, 18),
        decision: record.decision,
      );

      expect(
        () => repo.recordLegalNotice(invalid),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(() => prefs.setString(any(), any()));
    });
  });
}
