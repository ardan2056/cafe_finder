import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

  // BrewQuest Color Palette
  static const Color primary = Color(0xFF553722); // Deep Coffee Brown
  static const Color primaryContainer = Color(0xFF6F4E37);
  static const Color secondary = Color(0xFF735A3E); // Warm Latte
  static const Color secondaryContainer = Color(0xFFFDD9B7);
  static const Color tertiary = Color(0xFF533913); // Creamy Beige
  static const Color tertiaryContainer = Color(0xFFE7C08E);

  // Dynamic getters for colors that are used as variables
  static Color get background => themeModeNotifier.value == ThemeMode.dark ? const Color(0xFF15100C) : const Color(0xFFFAF9F8);
  static Color get text => themeModeNotifier.value == ThemeMode.dark ? const Color(0xFFFAF9F8) : const Color(0xFF1A1C1C);

  // Legacy mappings for backwards compatibility with existing screens
  static Color get navy => background; // Maps screen backgrounds dynamically
  static const Color gold = primary; // Maps main action elements to Coffee Brown
  static const Color blue = secondary; // Maps secondary elements to Latte
  
  // Use a neutral soft clay/brown that works in both light and dark mode
  static const Color textLight = Color(0xFF8C7E77); // Soft muted warm brown (readable on both light and dark)
  static const Color gray = Color(0xFF82746D); // Soft clay outline
  static const Color lightGray = textLight;

  // UI constants for consistent styling
  static const double cardRadius = 24.0;
  static Color get surface => themeModeNotifier.value == ThemeMode.dark ? const Color(0xFF241C15) : const Color(0xFFFFFFFF);

  static BoxDecoration cardDecoration({double radius = cardRadius}) =>
      BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFD4C3BA).withValues(alpha: 0.4)),
      );

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', mode == ThemeMode.dark);
    } catch (_) {}
  }

  static Future<void> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_mode') ?? false;
      themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {}
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFAF9F8),
    primaryColor: primary,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: primary,
      primaryContainer: primaryContainer,
      secondary: secondary,
      secondaryContainer: secondaryContainer,
      tertiary: tertiary,
      tertiaryContainer: tertiaryContainer,
      surface: Colors.white,
      onSurface: Color(0xFF1A1C1C),
      onPrimary: Colors.white,
      error: Color(0xFFBA1A1A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFAF9F8),
      elevation: 0,
      centerTitle: true,
      foregroundColor: Color(0xFF1A1C1C),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C)),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1C)),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1C1C)),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF1A1C1C)),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF8C7E77)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF15100C),
    primaryColor: const Color(0xFFE7C08E), // Gold-like coffee accent in dark mode
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFE7C08E),
      primaryContainer: Color(0xFF553722),
      secondary: Color(0xFFFAF9F8),
      secondaryContainer: Color(0xFF735A3E),
      tertiary: Color(0xFFFAF9F8),
      tertiaryContainer: Color(0xFFE7C08E),
      surface: Color(0xFF241C15), // Warm dark card color
      onSurface: Color(0xFFFAF9F8),
      onPrimary: Color(0xFF15100C),
      error: Color(0xFFCF6679),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF15100C),
      elevation: 0,
      centerTitle: true,
      foregroundColor: Color(0xFFFAF9F8),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFAF9F8)),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFAF9F8)),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFFAF9F8)),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: Color(0xFFFAF9F8)),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFFD4C3BA)),
    ),
  );
}


