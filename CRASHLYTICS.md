# Firebase Crashlytics Integration (Android & iOS)

1. Add Firebase to your Android/iOS apps (console).
2. Add `firebase_crashlytics` to `pubspec.yaml` and run `flutter pub get`.
3. Initialize Crashlytics in `main()` after Firebase initialization:

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

await Firebase.initializeApp();
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

4. Android: enable NDK reporting if needed; configure `google-services.json` and keep it out of source control.
5. iOS: add `GoogleService-Info.plist`, enable Crashlytics in Xcode, and upload dSYMs.
6. CI: upload symbols and set `SENTRY_DSN` or Crashlytics API keys as secrets.

Refer to Firebase docs for detailed platform steps.
