import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'bootstrap/firebase_bootstrap.dart';
import 'core/firebase_status.dart' as fb_status;
import 'services/diagnostic_report_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeFirebase();
  } catch (e, st) {
    // Capture error so UI can display a helpful message instead of failing silently.
    fb_status.firebaseInitError = e.toString();
    // keep running the app so developer can see an in-app message and continue debugging
    // also print to console for more details
    // ignore: avoid_print
    print('Firebase initialization error: $e');
    // ignore: avoid_print
    print(st);
  }

  await DiagnosticReportService.instance.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(DiagnosticReportService.instance.recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      source: 'flutter_error',
      extra: <String, dynamic>{
        'library': details.library,
        'context': details.context?.toString(),
      },
    ));
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(DiagnosticReportService.instance.recordError(
      error,
      stack,
      source: 'platform_error',
    ));
    return true;
  };

  runZonedGuarded(() {
    runApp(const CafeFinderApp());
  }, (error, stack) {
    unawaited(DiagnosticReportService.instance.recordError(
      error,
      stack,
      source: 'zone_error',
    ));
  });
}

Future<void> _initializeFirebase() async {
  await initializeFirebase();
}
