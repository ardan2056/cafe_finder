# Crashlytics Finalization Checklist

This document describes the remaining manual steps to enable Firebase Crashlytics on Android and iOS, and suggested CI steps for symbol upload.

## 1) Add SDK to Flutter
- Ensure `firebase_crashlytics` is in `pubspec.yaml` and run `flutter pub get`.

## 2) Android
1. Add `google-services.json` (download from Firebase console) to `android/app/`.
2. In `android/build.gradle` (project-level) ensure `com.google.gms:google-services` is in `dependencies`:

```gradle
classpath 'com.google.gms:google-services:4.3.15'
```

3. In `android/app/build.gradle` apply the plugin at the bottom:

```gradle
apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'
```

4. (Optional) Enable NDK if you need native crash reporting.

5. Keep `google-services.json` out of source control and reference it during CI via secrets or an artifact.

## 3) iOS
1. Download `GoogleService-Info.plist` and add to `ios/Runner` via Xcode (do NOT commit secrets to repository).
2. In Xcode, enable Crashlytics and ensure `FirebaseCrashlytics` is added to the app target frameworks.
3. Ensure bitcode / dSYM upload is configured for symbolication.

## 4) App initialization (already wired)
- The app initializes `Firebase` and `DiagnosticReportService` which calls `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(...)` based on user preference.
- We also capture Flutter errors and platform errors and forward to `DiagnosticReportService.recordError()`.

## 5) CI: uploading symbols (recommended)
- For Android mapping file upload, after `flutter build apk --release` add:

```yaml
- name: Upload Proguard mapping
  run: |
    # example using firebase CLI
    firebase crashlytics:upload-mappings --app=<ANDROID_APP_ID> android/app/build/outputs/mapping/release/mapping.txt
  env:
    FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

- For iOS dSYMs, use `firebase crashlytics:symbols:upload` with the path to dSYMs and appropriate auth.

## 6) Security & secrets
- Store `FIREBASE_TOKEN` (or service account key) as GitHub Secrets.
- Avoid committing `google-services.json` / `GoogleService-Info.plist` to the repo.

## 7) Local verification
- Run the app locally and trigger a non-fatal error to verify events arrive in Crashlytics (or emulator if using emulator for auth/firestore).

## Notes
- If you want me to edit native Android/iOS project files automatically, say so explicitly. I recommend manual review of native changes to avoid accidental credential commits.
