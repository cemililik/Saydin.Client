import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saydin/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPrefs extends Mock implements SharedPreferencesAsync {}

void main() {
  late _MockPrefs prefs;
  late OnboardingRepositoryImpl repo;

  setUp(() {
    prefs = _MockPrefs();
    repo = OnboardingRepositoryImpl(prefs);
  });

  group('OnboardingRepositoryImpl.recordLegalAcceptance', () {
    test('version >= 1 ise prefs.setInt çağrılır', () async {
      when(() => prefs.setInt(any(), any())).thenAnswer((_) async {});

      await repo.recordLegalAcceptance(1);

      verify(() => prefs.setInt('legal_acceptance_version', 1)).called(1);
    });

    test('version 0 → ArgumentError, prefs çağrılmaz', () async {
      expect(
        () => repo.recordLegalAcceptance(0),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(() => prefs.setInt(any(), any()));
    });

    test('version negatif → ArgumentError, prefs çağrılmaz', () async {
      expect(
        () => repo.recordLegalAcceptance(-3),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(() => prefs.setInt(any(), any()));
    });
  });
}
