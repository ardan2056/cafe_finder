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
  // Sentry DSN for error reporting. Provide via --dart-define=SENTRY_DSN=your_dsn
  static const String sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');

    // Map tile configuration for flutter_map.
    // Default is public OSM tiles for development only.
    // For production, provide your own provider URL and key via dart-define.
    static const String mapTileUrlTemplate = String.fromEnvironment(
        'MAP_TILE_URL_TEMPLATE',
        defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );

    static const String mapTileFallbackUrlTemplate = String.fromEnvironment(
        'MAP_TILE_FALLBACK_URL_TEMPLATE',
        defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    );

    static const String mapTileApiKey = String.fromEnvironment(
        'MAP_TILE_API_KEY',
        defaultValue: '',
    );

    static const String mapTileUserAgentPackage = String.fromEnvironment(
        'MAP_TILE_USER_AGENT_PACKAGE',
        defaultValue: 'com.cafefinder.app',
    );
}
