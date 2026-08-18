import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyLegalNotice = 'legal_notice_record_v2';

  final SharedPreferencesAsync _prefs;

  OnboardingRepositoryImpl(this._prefs);

  @override
  Future<bool> isOnboardingCompleted() async {
    return await _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  @override
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_keyOnboardingCompleted, true);
  }

  @override
  Future<void> recordLegalNotice(LegalNoticeRecord record) async {
    if (record.version < 1 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(record.bundleSha256) ||
        record.privacyDocumentId.trim().isEmpty ||
        record.kvkkDocumentId.trim().isEmpty ||
        record.locale.trim().isEmpty ||
        !record.recordedAtUtc.isUtc) {
      throw ArgumentError.value(
        record,
        'record',
        'Invalid legal notice record',
      );
    }
    await _prefs.setString(
      _keyLegalNotice,
      jsonEncode({
        'version': record.version,
        'bundleSha256': record.bundleSha256,
        'privacyDocumentId': record.privacyDocumentId,
        'kvkkDocumentId': record.kvkkDocumentId,
        'locale': record.locale,
        'recordedAtUtc': record.recordedAtUtc.toIso8601String(),
        'decision': record.decision.name,
      }),
    );
  }

  @override
  Future<LegalNoticeRecord?> getLegalNotice() async {
    final encoded = await _prefs.getString(_keyLegalNotice);
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) return null;
      final version = json['version'];
      final bundleSha256 = json['bundleSha256'];
      final privacyDocumentId = json['privacyDocumentId'];
      final kvkkDocumentId = json['kvkkDocumentId'];
      final locale = json['locale'];
      final recordedAt = json['recordedAtUtc'];
      final decision = json['decision'];
      if (version is! int ||
          bundleSha256 is! String ||
          privacyDocumentId is! String ||
          kvkkDocumentId is! String ||
          locale is! String ||
          recordedAt is! String ||
          decision is! String) {
        return null;
      }
      final timestamp = DateTime.tryParse(recordedAt);
      final parsedDecision = LegalNoticeDecision.values
          .where((value) => value.name == decision)
          .firstOrNull;
      if (timestamp == null || !timestamp.isUtc || parsedDecision == null) {
        return null;
      }
      return LegalNoticeRecord(
        version: version,
        bundleSha256: bundleSha256,
        privacyDocumentId: privacyDocumentId,
        kvkkDocumentId: kvkkDocumentId,
        locale: locale,
        recordedAtUtc: timestamp,
        decision: parsedDecision,
      );
    } on FormatException {
      return null;
    }
  }
}
