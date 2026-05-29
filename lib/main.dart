import 'package:flutter/material.dart';
import 'app.dart';
import 'bootstrap/firebase_bootstrap.dart';
import 'core/firebase_status.dart' as fb_status;

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

  runApp(const CafeFinderApp());
}

Future<void> _initializeFirebase() async {
  await initializeFirebase();
}
