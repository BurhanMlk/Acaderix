import 'package:flutter/material.dart';

/// Central color palette for Acaderix.
///
/// Grounded in an Academic Editorial / Institutional Precision aesthetic:
/// warm alabaster paper canvas, crisp white elevated surfaces, deep Oxford
/// Navy primary, and restrained academic teal & semantic accents.
abstract final class AppColors {
  static const Color seed = Color(0xFF1B365D); // Oxford Navy

  // Brand
  static const Color primary = Color(0xFF1B365D); // Oxford Navy
  static const Color primaryLight = Color(0xFFE8EEF5); // Soft Slate-Blue
  static const Color secondary = Color(0xFF0F766E); // Academic Teal
  static const Color secondaryLight = Color(0xFFE6F4F1);

  // Semantic
  static const Color success = Color(0xFF15803D);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFB45309);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF0369A1);
  static const Color infoLight = Color(0xFFF0F9FF);

  // Surfaces
  static const Color background = Color(0xFFF7F6F2); // Warm Alabaster Paper
  static const Color surface = Color(0xFFFFFFFF); // Crisp Elevated White
  static const Color surfaceMuted = Color(0xFFF0EFEA); // Warm Stone Well

  // Borders
  static const Color border = Color(0xFFE4E2DC); // Warm Hairline
  static const Color borderLight = Color(0xFFECEAE4); // Subtle Divider

  // Text / Ink
  static const Color textPrimary = Color(0xFF14181F); // Deep Charcoal Ink
  static const Color textSecondary = Color(0xFF3E4652); // Slate Ink
  static const Color textTertiary = Color(0xFF68707C); // Muted Slate
  static const Color textMuted = Color(0xFF949BA6); // Subtle Ink
}
