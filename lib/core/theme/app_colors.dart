import 'package:flutter/material.dart';

/// Central color palette for the product.
///
/// Prefer semantic scheme roles from [Theme.of] over these raw values; this
/// palette is the source used to seed the Material 3 color schemes.
abstract final class AppColors {
  static const Color seed = Color(0xFF4F46E5); // Indigo 600

  // Brand
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo 50

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFF0F9FF);

  // Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF9FAFB);

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
}
