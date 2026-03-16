import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  configureDependencies();

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment(
        'SENTRY_DSN',
        defaultValue: '', // DSN yoksa Sentry devre dışı kalır
      );
      options.environment = const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      );
      options.tracesSampleRate = 0.2; // %20 performance tracing
      options.attachScreenshot = true;
    },
    appRunner: () => runApp(
      DefaultAssetBundle(bundle: SentryAssetBundle(), child: const SaydinApp()),
    ),
  );
}
