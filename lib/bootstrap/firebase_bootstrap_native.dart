import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (_) {
    // Fallback: initialize without explicit options. On some platforms
    // the default configuration may work, or the app can be configured
    // by regenerating `lib/firebase_options.dart` with the FlutterFire CLI.
    await Firebase.initializeApp();
  }

  // Run a quick Firestore availability check and log the result.
  try {
    final firestore = FirebaseFirestore.instance;
    final doc = firestore.collection('diagnostics').doc('last_start');
    final write = doc.set({
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'platform': 'windows',
    });
    await write.timeout(const Duration(seconds: 10));
    developer.log('Firestore diagnostic write succeeded', name: 'firebase_bootstrap');
  } on TimeoutException catch (e, st) {
    developer.log('Firestore diagnostic write timed out: $e', name: 'firebase_bootstrap', stackTrace: st);
  } catch (e, st) {
    developer.log('Firestore diagnostic write failed: $e', name: 'firebase_bootstrap', stackTrace: st);
  }
}
