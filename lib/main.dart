import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'bootstrap/firebase_bootstrap.dart';
import 'core/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

  if (Config.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) => options.dsn = Config.sentryDsn,
      appRunner: () => runApp(const CafeFinderApp()),
    );
  } else {
    runApp(const CafeFinderApp());
  }
}

Future<void> _initializeFirebase() async {
  await initializeFirebase();
}
