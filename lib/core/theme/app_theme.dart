import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Clean Material 3 light theme used across all screens and roles in the app.
abstract final class AppTheme {
  static ThemeData get light => _buildLightTheme();
  static ThemeData get dark => _buildLightTheme();

  static ThemeData _buildLightTheme() {
    const primary = Color(0xFF4F46E5); // Indigo 600
    const secondary = Color(0xFF7C3AED); // Violet 600
    const tertiary = Color(0xFF0284C7); // Sky 600
    const errorColor = Color(0xFFDC2626);

    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEEF2FF), // Indigo 50
      onPrimaryContainer: Color(0xFF312E81), // Indigo 900
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFF5F3FF), // Violet 50
      onSecondaryContainer: Color(0xFF4C1D95), // Violet 900
      tertiary: tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFF0F9FF), // Sky 50
      onTertiaryContainer: Color(0xFF0C4A6E), // Sky 900
      error: errorColor,
      onError: Colors.white,
      errorContainer: Color(0xFFFEF2F2), // Red 50
      onErrorContainer: Color(0xFF991B1B), // Red 800
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF111827), // Gray 900
      onSurfaceVariant: Color(0xFF6B7280), // Gray 500
      outline: Color(0xFFD1D5DB), // Gray 300
      outlineVariant: Color(0xFFE5E7EB), // Gray 200
      surfaceContainerHighest: Color(0xFFF3F4F6), // Gray 100
      surfaceContainerHigh: Color(0xFFF9FAFB), // Gray 50
      surfaceContainer: Color(0xFFF9FAFB),
      surfaceContainerLow: Color(0xFFFCFCFD),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      shadow: Color(0x1A000000), // 10% black
      scrim: Color(0x33000000), // 20% black
    );

    const textTheme = TextTheme(
      displayLarge: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w700,
      ),
      displaySmall: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      titleMedium: TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: TextStyle(
        color: Color(0xFF374151),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: TextStyle(color: Color(0xFF374151), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      labelLarge: TextStyle(
        color: Color(0xFF374151),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      labelSmall: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      cardColor: AppColors.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Cards — white with subtle border
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // AppBar — white with bottom border
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: AppColors.border,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Input Fields — light fill, gray border
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textTertiary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          minimumSize: const Size(64, 48),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Dialogs — white with subtle shadow
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),

      // Popups & Dropdowns
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        textStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        iconColor: AppColors.textSecondary,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        selectedColor: const Color(0xFFEEF2FF), // Indigo 50
        secondarySelectedColor: const Color(0xFFEEF2FF),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        brightness: Brightness.light,
      ),

      // Dividers & Lists
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textTertiary,
      ),

      // Navigation Drawer & Bottom Sheets
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.surface),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Snackbars — dark for contrast
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937), // Gray 800
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
