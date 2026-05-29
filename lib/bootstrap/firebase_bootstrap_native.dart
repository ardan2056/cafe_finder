import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // If the environment requests emulator usage, connect Firestore and Auth
  // to local emulators. Set `USE_FIREBASE_EMULATOR=1` in the environment
  // before running the app to enable this (see scripts/start_firebase_emulator.ps1).
  try {
    final useEmu = Platform.environment['USE_FIREBASE_EMULATOR'] == '1';
    if (useEmu) {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      developer.log(
          'Connected to Firebase emulators (Auth:9099 Firestore:8080)',
          name: 'firebase_bootstrap');
    }
  } catch (e, st) {
    developer.log('Failed to configure Firebase emulators: $e',
        name: 'firebase_bootstrap', stackTrace: st);
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
    developer.log('Firestore diagnostic write succeeded',
        name: 'firebase_bootstrap');
  } on TimeoutException catch (e, st) {
    developer.log('Firestore diagnostic write timed out: $e',
        name: 'firebase_bootstrap', stackTrace: st);
  } catch (e, st) {
    developer.log('Firestore diagnostic write failed: $e',
        name: 'firebase_bootstrap', stackTrace: st);
  }

  await _flushQueuedFeedback();
}

Future<void> _flushQueuedFeedback() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final queued = prefs.getStringList('queued_feedback') ?? [];
    if (queued.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final remaining = <String>[];

    for (final message in queued) {
      try {
        await firestore.collection('feedback').add({
          'uid': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
          'message': message,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'queued',
        });
      } catch (e, st) {
        remaining.add(message);
        developer.log('Failed to flush queued feedback item: $e',
            name: 'firebase_bootstrap', stackTrace: st);
      }
    }

    if (remaining.isEmpty) {
      await prefs.remove('queued_feedback');
    } else {
      await prefs.setStringList('queued_feedback', remaining);
    }
  } catch (e, st) {
    developer.log('Failed to flush queued feedback: $e',
        name: 'firebase_bootstrap', stackTrace: st);
  }
}
