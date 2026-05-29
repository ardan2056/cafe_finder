/// Centralized config that reads API keys from `--dart-define` at build/run time.
class Config {
  // Provide keys via --dart-define=GOOGLE_MAPS_API_KEY=xxx
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  // Optional explicit platform keys
  static const String googleMapsAndroidKey =
      String.fromEnvironment('GOOGLE_MAPS_ANDROID_KEY', defaultValue: '');
  static const String googleMapsiOSKey =
      String.fromEnvironment('GOOGLE_MAPS_IOS_KEY', defaultValue: '');
  // Allow anonymous/guest sign-in when enabled via --dart-define.
  // Default: false (recommended for production/demo safety)
  static const bool allowAnonymousLogin =
      bool.fromEnvironment('ALLOW_ANONYMOUS_LOGIN', defaultValue: true);
  // When true, show a minimal profile view: hide preferences, admin panel,
  // and extra settings. Useful for simpler UX or demo flows.
  static const bool simpleProfileMode =
      bool.fromEnvironment('SIMPLE_PROFILE_MODE', defaultValue: true);
}
