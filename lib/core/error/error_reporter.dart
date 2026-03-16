import 'package:sentry_flutter/sentry_flutter.dart';

/// Sentry'ye hata raporlar. Test ortamında mock'lanabilir.
class ErrorReporter {
  const ErrorReporter();

  Future<void> report(
    Object exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? extras,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (context != null) scope.setTag('context', context);
        if (extras != null && extras.isNotEmpty) {
          scope.setContexts('extra', extras);
        }
      },
    );
  }

  Future<void> addBreadcrumb(String message, {String? category}) async {
    await Sentry.addBreadcrumb(
      Breadcrumb(message: message, category: category ?? 'app'),
    );
  }
}
