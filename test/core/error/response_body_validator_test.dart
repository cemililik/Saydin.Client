import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/error/response_body_validator.dart';

void main() {
  group('ResponseBodyValidator finite double', () {
    test('sıfır ve temsil edilebilen büyük finite değerleri kabul eder', () {
      for (final value in [0.0, double.maxFinite, -double.maxFinite]) {
        expect(ResponseBodyValidator.requireFiniteDouble(value, 'rate'), value);
      }
    });

    test('NaN ve iki Infinity yönünü reddeder', () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => ResponseBodyValidator.requireFiniteDouble(value, 'rate'),
          throwsFormatException,
        );
      }
    });

    test('optional yalnız null için null döner, yanlış tipi reddeder', () {
      expect(ResponseBodyValidator.optionalFiniteDouble(null, 'rate'), isNull);
      expect(
        () => ResponseBodyValidator.optionalFiniteDouble('12.5', 'rate'),
        throwsFormatException,
      );
    });
  });
}
