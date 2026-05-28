import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Run flutterfire configure to generate Firebase options for Cafe Finder.',
    );
  }
}
