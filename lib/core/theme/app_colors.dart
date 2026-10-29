import 'package:flutter/material.dart';

/// Central color palette for the product.
///
/// Prefer semantic scheme roles from [Theme.of] over these raw values; this
/// palette is the source used to seed the Material 3 color schemes.
abstract final class AppColors {
  static const Color seed = Color(0xFF4F46E5); // Indigo 600

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);

  static const Color surfaceMuted = Color(0xFFF4F4F5);
}
