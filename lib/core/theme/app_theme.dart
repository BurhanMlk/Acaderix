import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized Glassmorphism theme used across all screens and roles in the app.
abstract final class AppTheme {
  static ThemeData get light => _buildGlassTheme();
  static ThemeData get dark => _buildGlassTheme();

  static ThemeData _buildGlassTheme() {
    const primary = Color(0xFF6366F1); // Indigo
    const secondary = Color(0xFFA855F7); // Purple
    const tertiary = Color(0xFF0EA5E9); // Sky blue
    const errorColor = Color(0xFFEF4444);

    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF4338CA).withValues(alpha: 0.7),
      onPrimaryContainer: const Color(0xFFE0E7FF),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF6B21A8).withValues(alpha: 0.7),
      onSecondaryContainer: const Color(0xFFF3E8FF),
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFF0369A1).withValues(alpha: 0.7),
      onTertiaryContainer: const Color(0xFFE0F2FE),
      error: errorColor,
      onError: Colors.white,
      errorContainer: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
      onErrorContainer: const Color(0xFFFEE2E2),
      surface: Colors.white.withValues(alpha: 0.08),
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFCBD5E1), // Light slate for subtitles & secondary text
      outline: Colors.white.withValues(alpha: 0.24),
      outlineVariant: Colors.white.withValues(alpha: 0.16),
      surfaceContainerHighest: Colors.white.withValues(alpha: 0.14),
      surfaceContainerHigh: Colors.white.withValues(alpha: 0.11),
      surfaceContainer: Colors.white.withValues(alpha: 0.08),
      surfaceContainerLow: Colors.white.withValues(alpha: 0.05),
      surfaceContainerLowest: Colors.white.withValues(alpha: 0.03),
      shadow: Colors.black.withValues(alpha: 0.4),
      scrim: Colors.black.withValues(alpha: 0.6),
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
      labelSmall: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: const Color(0xFF0F172A),
      cardColor: Colors.white.withValues(alpha: 0.08),
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Universal Transparent Glass Cards
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.16),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Frosted Transparent AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF0B1120),
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Glass Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF818CF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1B4B).withValues(alpha: 0.95),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 14,
          height: 1.4,
        ),
      ),

      // Popups & Dropdowns
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1E1B4B).withValues(alpha: 0.95),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 14),
        iconColor: Colors.white,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        selectedColor: primary.withValues(alpha: 0.35),
        secondarySelectedColor: primary.withValues(alpha: 0.35),
        labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        brightness: Brightness.dark,
      ),

      // Dividers & Lists
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.12),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Colors.white,
        iconColor: Colors.white,
      ),

      // Navigation Drawer & Bottom Sheets
      drawerTheme: DrawerThemeData(
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.95),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1E1B4B).withValues(alpha: 0.95),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E1B4B).withValues(alpha: 0.95),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
      ),
    );
  }
}
