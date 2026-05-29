/// A tiny module to share Firebase initialization status across the app.
String? firebaseInitError;

/// Whether Firebase initialization completed successfully.
bool get isFirebaseReady => firebaseInitError == null;
