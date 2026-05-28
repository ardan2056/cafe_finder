import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF0F172A);
  static const Color gold = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF38BDF8);
  static const Color gray = Color(0xFF94A3B8);
  static const Color lightGray = Color(0xFFCBD5E1);

  // UI constants for consistent styling
  static const double cardRadius = 20.0;
  static Color surface = const Color(0xFF0B1220);

  static BoxDecoration cardDecoration({double radius = cardRadius}) =>
      BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    primaryColor: gold,
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: blue,
      surface: Color(0xFF111827),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: navy,
      elevation: 0,
      centerTitle: true,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    ),
  );
}
