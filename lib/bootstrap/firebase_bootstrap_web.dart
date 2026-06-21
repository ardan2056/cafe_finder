import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'cafe_seed_data.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const useEmu = String.fromEnvironment('USE_FIREBASE_EMULATOR') == '1' ||
      bool.fromEnvironment('USE_FIREBASE_EMULATOR');
  if (useEmu) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }

  // Auto-seed cafes if the database is empty (both on emulator and production Firestore)
  unawaited(seedCafesIfEmpty());
  unawaited(seedCommunitiesAndEventsIfEmpty());
}
