import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// Compatibility helper: use `withValues(alpha: x)` across the codebase.
  /// Avoid calling `withOpacity` (deprecated) to prevent analyzer warnings.
  Color withValues({required double alpha}) {
    // Use the normalized r/g/b (0..1) multiplied by 255 and clamped to 0..255.
    final intR = (r * 255.0).round().clamp(0, 255);
    final intG = (g * 255.0).round().clamp(0, 255);
    final intB = (b * 255.0).round().clamp(0, 255);
    return Color.fromRGBO(intR, intG, intB, alpha);
  }
}
