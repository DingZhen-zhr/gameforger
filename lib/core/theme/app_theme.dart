import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Cosmic Forge OS tokens from the Claude handoff.
  static const Color primary = Color(0xFF7B5CFF);
  static const Color primaryContainer = Color(0xFF2A1A6A);
  static const Color secondary = Color(0xFF4FC9E8);
  static const Color secondaryContainer = Color(0xFF103D4E);
  static const Color tabProject = Color(0xFF9A7DFF);
  static const Color tabGallery = Color(0xFF4FC9E8);
  static const Color tabSettings = Color(0xFFCBB8FF);
  static const Color warmAccent = Color(0xFFF2C36B);
  static const Color bgDark = Color(0xFF04030A);
  static const Color surfaceDark = Color(0xFF0A0916);
  static const Color surfaceVariant = Color(0xFF14121C);
  static const Color outlineDark = Color(0xFF272438);
  static const Color textPrimary = Color(0xFFF4F1FF);
  static const Color textSecondary = Color(0xB8F4F1FF);
  static const Color textTertiary = Color(0x73F4F1FF);
  static const Color error = Color(0xFFFF5A6B);
  static const Color gold = Color(0xFFF2C36B);
  static const Color cyan = Color(0xFF9BEAFF);
  static const Color online = Color(0xFF5BE7A7);

  // Liquid Glass surface colors (semi-transparent overlays)
  static const Color glassClear = Color(0x0FFFFFFF);
  static const Color glassTinted = Color(0x14FFFFFF);
  static const Color glassStrong = Color(0x24FFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color glassShadow = Color(0x7A000000);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surfaceDark,
        surfaceContainer: surfaceVariant,
        surfaceContainerHigh: surfaceVariant,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        onError: Colors.white,
        outline: outlineDark,
      ),
      scaffoldBackgroundColor: bgDark,
      platform: TargetPlatform.iOS,

      // --- AppBar ---
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      // --- Tab Bar ---
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),

      // --- Cards ---
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // --- Buttons ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // --- Text Fields ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassTinted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: secondary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textTertiary),
      ),

      // --- Snackbar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),

      // --- Dialog ---
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: outlineDark,
        thickness: 0.5,
        space: 0,
      ),

      // --- iOS-style Typography ---
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}
