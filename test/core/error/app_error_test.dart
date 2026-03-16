import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/error/app_error.dart';

void main() {
  group('AppError', () {
    test('PriceNotFoundError is an AppError', () {
      const error = PriceNotFoundError();
      expect(error, isA<AppError>());
    });

    test('DailyLimitError carries resetAt', () {
      final reset = DateTime.utc(2026, 3, 17);
      final error = DailyLimitError(resetAt: reset);
      expect(error.resetAt, equals(reset));
    });

    test('NoInternetError is an AppError', () {
      const error = NoInternetError();
      expect(error, isA<AppError>());
    });

    test('ServerError carries optional statusCode', () {
      const error = ServerError(statusCode: 500);
      expect(error.statusCode, equals(500));

      const noStatus = ServerError();
      expect(noStatus.statusCode, isNull);
    });

    test('UnknownError carries optional cause', () {
      final cause = Exception('test');
      final error = UnknownError(cause: cause);
      expect(error.cause, equals(cause));
    });
  });
}
