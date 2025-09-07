import 'package:flutter/material.dart';

// Export Flutter Material for convenience
export 'package:flutter/material.dart';

/// Glass Design Theme inspired by iOS 16 with professional styling
class GlassTheme {
  // iOS 16 inspired Glass Colors
  static const Color primary = Color(0xFF007AFF);
  static const Color secondary = Color(0xFF5856D6);
  static const Color accent = Color(0xFF32D74B);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF32D74B);
  static const Color info = Color(0xFF007AFF);
  
  // Glass Background Colors
  static const Color glassBackground = Color(0x15FFFFFF);
  static const Color glassBorder = Colors.transparent;
  static const Color glassHighlight = Color(0x40FFFFFF);
  static const Color glassShadow = Color(0x40000000);
  static const Color glassOverlay = Color(0x10FFFFFF);
  
  // Advanced Glass Effects
  static const Color ultraThinGlass = Color(0x08FFFFFF);
  static const Color thinGlass = Color(0x12FFFFFF);
  static const Color thickGlass = Color(0x25FFFFFF);
  static const Color materialGlass = Color(0x35FFFFFF);
  
  // Text Colors on Glass
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xCCFFFFFF);
  static const Color textTertiary = Color(0x99FFFFFF);
  static const Color textDisabled = Color(0x66FFFFFF);
  static const Color textOnGlass = Color(0xFFFFFFFF);
  
  // Background Gradients
  static const List<Color> backgroundGradient = [
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
    Color(0xFF0F3460),
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFF007AFF),
    Color(0xFF5856D6),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF32D74B),
    Color(0xFF30D158),
  ];
  
  static const List<Color> warningGradient = [
    Color(0xFFFF9500),
    Color(0xFFFF8C00),
  ];
  
  // Glass Theme Data
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'SF Pro Display', // iOS font family
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: Color(0x20FFFFFF),
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 19, // 22 * 0.85
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 48, // 57 * 0.85
          fontWeight: FontWeight.w300,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 38, // 45 * 0.85
          fontWeight: FontWeight.w300,
          letterSpacing: 0,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 31, // 36 * 0.85
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 27, // 32 * 0.85
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 24, // 28 * 0.85
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 20, // 24 * 0.85
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 19, // 22 * 0.85
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 14, // 16 * 0.85
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontSize: 12, // 14 * 0.85
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          color: textSecondary,
          fontSize: 14, // 16 * 0.85
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 12, // 14 * 0.85
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          color: textTertiary,
          fontSize: 10, // 12 * 0.85
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 12, // 14 * 0.85
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 10, // 12 * 0.85
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: textTertiary,
          fontSize: 9, // 11 * 0.85
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17), // 20 * 0.85
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // 24*0.85, 16*0.85
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: glassBorder, width: 1),
          backgroundColor: glassBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17), // 20 * 0.85
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), // 24*0.85, 16*0.85
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17), // 20*0.85
          borderSide: BorderSide(color: glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17), // 20*0.85
          borderSide: BorderSide(color: glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17), // 20*0.85
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17), // 20*0.85
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17), // 20*0.85
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14), // 20*0.85, 16*0.85
      ),
      cardTheme: CardThemeData(
        color: glassBackground,
        shadowColor: glassShadow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 24*0.85
          side: BorderSide(color: glassBorder, width: 1),
        ),
      ),
    );
  }
}
