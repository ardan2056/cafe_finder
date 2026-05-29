// GENERATED FILE - Put your Firebase web config here
// Created from the Firebase Console snapshot provided by the user.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions have not been configured for this platform.\n'
      'Run `flutterfire configure` to generate platform-specific Firebase options.'
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8SvVWuePImsFy_ju46BQkriCsQaVRPcc',
    authDomain: 'cafee-finder.firebaseapp.com',
    projectId: 'cafee-finder',
    storageBucket: 'cafee-finder.firebasestorage.app',
    messagingSenderId: '913193457524',
    appId: '1:913193457524:web:faf7834daf36f06a4f3e21',
    measurementId: 'G-5Q2Y1BW819',
  );
}
