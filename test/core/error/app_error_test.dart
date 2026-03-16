import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/core/error/app_error.dart';

void main() {
  group('AppError', () {
    test('PriceNotFoundError_created_isAppError', () {
      const error = PriceNotFoundError();
      expect(error, isA<AppError>());
    });

    test('DailyLimitError_withResetAt_carriesResetAt', () {
      final reset = DateTime.utc(2026, 3, 17);
      final error = DailyLimitError(resetAt: reset);
      expect(error.resetAt, equals(reset));
    });

    test('NoInternetError_created_isAppError', () {
      const error = NoInternetError();
      expect(error, isA<AppError>());
    });

    test('ServerError_withStatusCode_carriesStatusCode', () {
      const error = ServerError(statusCode: 500);
      expect(error.statusCode, equals(500));
    });

    test('ServerError_withoutStatusCode_hasNullStatusCode', () {
      const error = ServerError();
      expect(error.statusCode, isNull);
    });

    test('UnknownError_withCause_carriesCause', () {
      final cause = Exception('test');
      final error = UnknownError(cause: cause);
      expect(error.cause, equals(cause));
    });
  });
}
