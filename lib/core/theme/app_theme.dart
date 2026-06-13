import 'package:flutter/material.dart';

class _ForgePalette {
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color warmAccent;
  final Color bg;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color error;
  final Color gold;
  final Color cyan;
  final Color online;
  final Color glassClear;
  final Color glassTinted;
  final Color glassStrong;
  final Color glassBorder;
  final Color glassShadow;

  const _ForgePalette({
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.warmAccent,
    required this.bg,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.error,
    required this.gold,
    required this.cyan,
    required this.online,
    required this.glassClear,
    required this.glassTinted,
    required this.glassStrong,
    required this.glassBorder,
    required this.glassShadow,
  });
}

class AppTheme {
  AppTheme._();

  // GameForger v2 Direction B: editorial workshop, warm dark paper, forest green.
  static const _ForgePalette _dark = _ForgePalette(
    primary: Color(0xFF5BC078),
    primaryContainer: Color(0xFF0A1E10),
    secondary: Color(0xFFE4B454),
    secondaryContainer: Color(0xFF3A2C13),
    warmAccent: Color(0xFFE4B454),
    bg: Color(0xFF14120E),
    surface: Color(0xFF1F1B14),
    surfaceVariant: Color(0xFF29241B),
    outline: Color(0x33F4ECD8),
    textPrimary: Color(0xFFF4ECD8),
    textSecondary: Color(0xFFA89F8A),
    textTertiary: Color(0xFF75705F),
    error: Color(0xFFE5645A),
    gold: Color(0xFFE4B454),
    cyan: Color(0xFF9FCFAE),
    online: Color(0xFF5BC078),
    glassClear: Color(0x0FFFFFFF),
    glassTinted: Color(0x14FFFFFF),
    glassStrong: Color(0x24FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    glassShadow: Color(0x7A000000),
  );

  static const _ForgePalette _light = _ForgePalette(
    primary: Color(0xFF1E7A3E),
    primaryContainer: Color(0xFFD9EFDF),
    secondary: Color(0xFFA8761F),
    secondaryContainer: Color(0xFFF2E2BE),
    warmAccent: Color(0xFFA8761F),
    bg: Color(0xFFF7F4ED),
    surface: Color(0xFFFCFAF5),
    surfaceVariant: Color(0xFFEFE9DC),
    outline: Color(0x1A16140E),
    textPrimary: Color(0xFF16140E),
    textSecondary: Color(0xFF5F584C),
    textTertiary: Color(0xFF918A7C),
    error: Color(0xFFB5301E),
    gold: Color(0xFFA8761F),
    cyan: Color(0xFF3F7B59),
    online: Color(0xFF1E7A3E),
    glassClear: Color(0x0A000000),
    glassTinted: Color(0x0F16140E),
    glassStrong: Color(0x1716140E),
    glassBorder: Color(0x1F16140E),
    glassShadow: Color(0x26000000),
  );

  static _ForgePalette _active = _dark;

  static bool get isLight => identical(_active, _light);

  static void setLightMode(bool isLightMode) {
    _active = isLightMode ? _light : _dark;
  }

  static Color get primary => _active.primary;
  static Color get primaryContainer => _active.primaryContainer;
  static Color get secondary => _active.secondary;
  static Color get secondaryContainer => _active.secondaryContainer;
  static Color get tabProject => primary;
  static Color get tabGallery => primary;
  static Color get tabSettings => primary;
  static Color get warmAccent => _active.warmAccent;
  static Color get bgDark => _active.bg;
  static Color get surfaceDark => _active.surface;
  static Color get surfaceVariant => _active.surfaceVariant;
  static Color get outlineDark => _active.outline;
  static Color get textPrimary => _active.textPrimary;
  static Color get textSecondary => _active.textSecondary;
  static Color get textTertiary => _active.textTertiary;
  static Color get error => _active.error;
  static Color get gold => _active.gold;
  static Color get cyan => _active.cyan;
  static Color get online => _active.online;

  // Liquid Glass surface colors (semi-transparent overlays)
  static Color get glassClear => _active.glassClear;
  static Color get glassTinted => _active.glassTinted;
  static Color get glassStrong => _active.glassStrong;
  static Color get glassBorder => _active.glassBorder;
  static Color get glassShadow => _active.glassShadow;

  static ThemeData get lightTheme => _buildTheme(
    palette: _light,
    brightness: Brightness.light,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
  );

  static ThemeData get darkTheme => _buildTheme(
    palette: _dark,
    brightness: Brightness.dark,
    onPrimary: const Color(0xFF0A1E10),
    onSecondary: Colors.black,
  );

  static ThemeData _buildTheme({
    required _ForgePalette palette,
    required Brightness brightness,
    required Color onPrimary,
    required Color onSecondary,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: brightness,
        primary: palette.primary,
        primaryContainer: palette.primaryContainer,
        secondary: palette.secondary,
        secondaryContainer: palette.secondaryContainer,
        surface: palette.surface,
        surfaceContainer: palette.surfaceVariant,
        surfaceContainerHigh: palette.surfaceVariant,
        error: palette.error,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onSurface: palette.textPrimary,
        onSurfaceVariant: palette.textSecondary,
        onError: Colors.white,
        outline: palette.outline,
      ),
      scaffoldBackgroundColor: palette.bg,
      platform: TargetPlatform.iOS,

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),

      // --- Tab Bar ---
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      ),

      // --- Cards ---
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // --- Buttons ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.primary),
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      // --- Text Fields ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.glassTinted,
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
          borderSide: BorderSide(color: palette.secondary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.error),
        ),
        labelStyle: TextStyle(color: palette.textSecondary),
        hintStyle: TextStyle(color: palette.textTertiary),
      ),

      // --- Snackbar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceVariant,
        contentTextStyle: TextStyle(color: palette.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),

      // --- Dialog ---
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),

      // --- Divider ---
      dividerTheme: DividerThemeData(
        color: palette.outline,
        thickness: 0.5,
        space: 0,
      ),

      // --- Editorial workshop typography ---
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: palette.textPrimary,
          fontSize: 44,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          fontFamily: 'Georgia',
        ),
        headlineMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          fontFamily: 'Georgia',
        ),
        titleLarge: TextStyle(
          color: palette.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          fontFamily: 'Georgia',
        ),
        titleMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleSmall: TextStyle(
          color: palette.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          color: palette.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: palette.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        bodySmall: TextStyle(
          color: palette.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          color: palette.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        labelMedium: TextStyle(
          color: palette.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
