import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Responsive Glass Theme that adapts to different screen sizes
class ResponsiveGlassTheme {
  /// Get responsive text theme based on screen size
  static TextTheme getResponsiveTextTheme(BuildContext context) {
    return TextTheme(
      // Display styles - for large headers
      displayLarge: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 48, tablet: 54, desktop: 60),
        fontWeight: FontWeight.w800,
        color: const Color(0xFFFFFFFF),
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 38, tablet: 42, desktop: 48),
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFFFFFF),
        letterSpacing: -0.4,
      ),
      displaySmall: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 30, tablet: 34, desktop: 38),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        letterSpacing: -0.3,
      ),
      
      // Headline styles - for section headers
      headlineLarge: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 26, tablet: 30, desktop: 34),
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFFFFFF),
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 22, tablet: 26, desktop: 30),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        letterSpacing: -0.1,
      ),
      headlineSmall: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 19, tablet: 22, desktop: 26),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        letterSpacing: 0,
      ),
      
      // Title styles - for component titles
      titleLarge: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 19, tablet: 22, desktop: 26),
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFFFFFF),
        letterSpacing: 0.1,
      ),
      titleMedium: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 16, tablet: 18, desktop: 20),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        letterSpacing: 0.2,
      ),
      titleSmall: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        letterSpacing: 0.3,
      ),
      
      // Body styles - for regular text
      bodyLarge: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 15, tablet: 17, desktop: 19),
        fontWeight: FontWeight.w500,
        color: const Color(0xCCFFFFFF),
        letterSpacing: 0.4,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
        fontWeight: FontWeight.w500,
        color: const Color(0xCCFFFFFF),
        letterSpacing: 0.4,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 12, tablet: 14, desktop: 16),
        fontWeight: FontWeight.w400,
        color: const Color(0x99FFFFFF),
        letterSpacing: 0.4,
        height: 1.3,
      ),
      
      // Label styles - for buttons and form labels
      labelLarge: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 12, tablet: 14, desktop: 16),
        fontWeight: FontWeight.w600,
        color: const Color(0xFFFFFFFF),
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: Responsive.fontSize(context, mobile: 10, tablet: 12, desktop: 14),
        fontWeight: FontWeight.w500,
        color: const Color(0xCCFFFFFF),
        letterSpacing: 0.5,
      ),
    );
  }

  /// Get responsive button theme based on screen size
  static ElevatedButtonThemeData getResponsiveButtonTheme(BuildContext context) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: const Color(0xFFFFFFFF),
        textStyle: TextStyle(
          fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18),
          fontWeight: FontWeight.w600,
        ),
        padding: Responsive.padding(
          context,
          mobile: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          desktop: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.borderRadius(context, mobile: 17, tablet: 20, desktop: 24),
          ),
        ),
      ),
    );
  }

  /// Get responsive input decoration theme based on screen size
  static InputDecorationTheme getResponsiveInputTheme(BuildContext context) {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x15FFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.borderRadius(context, mobile: 17, tablet: 20, desktop: 24),
        ),
        borderSide: const BorderSide(color: Colors.transparent, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.borderRadius(context, mobile: 17, tablet: 20, desktop: 24),
        ),
        borderSide: const BorderSide(color: Colors.transparent, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.borderRadius(context, mobile: 17, tablet: 20, desktop: 24),
        ),
        borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.borderRadius(context, mobile: 17, tablet: 20, desktop: 24),
        ),
        borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.borderRadius(context, mobile: 17, tablet: 20, desktop: 24),
        ),
        borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xCCFFFFFF)),
      hintStyle: const TextStyle(color: Color(0x99FFFFFF)),
      contentPadding: Responsive.padding(
        context,
        mobile: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    );
  }

  /// Get responsive card theme based on screen size
  static CardThemeData getResponsiveCardTheme(BuildContext context) {
    return CardThemeData(
      color: const Color(0x15FFFFFF),
      shadowColor: const Color(0x40000000),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.borderRadius(context, mobile: 20, tablet: 24, desktop: 28),
        ),
        side: const BorderSide(color: Colors.transparent, width: 1),
      ),
    );
  }

  /// Get responsive app bar theme based on screen size
  static AppBarTheme getResponsiveAppBarTheme(BuildContext context) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(
        color: const Color(0xFFFFFFFF),
        size: Responsive.iconSize(context, mobile: 24, tablet: 28, desktop: 32),
      ),
      titleTextStyle: TextStyle(
        color: const Color(0xFFFFFFFF),
        fontSize: Responsive.fontSize(context, mobile: 19, tablet: 22, desktop: 26),
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      toolbarHeight: Responsive.height(context, mobile: 85, tablet: 95, desktop: 105),
    );
  }
}
