import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class Responsive {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 1024;
  static const double _desktopBreakpoint = 1440;

  /// Check if current screen is mobile (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  /// Check if current screen is tablet (600px - 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= _mobileBreakpoint && width < _tabletBreakpoint;
  }

  /// Check if current screen is desktop (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _tabletBreakpoint;
  }

  /// Get responsive width based on screen size
  static double width(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive height based on screen size
  static double height(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive font size based on screen size
  static double fontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? (mobile * 1.1);
    } else {
      return desktop ?? tablet ?? (mobile * 1.2);
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets padding(BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }

  /// Get responsive spacing based on screen size
  static double spacing(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? (mobile * 1.2);
    } else {
      return desktop ?? tablet ?? (mobile * 1.5);
    }
  }

  /// Get responsive icon size based on screen size
  static double iconSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? (mobile * 1.1);
    } else {
      return desktop ?? tablet ?? (mobile * 1.3);
    }
  }

  /// Get responsive border radius based on screen size
  static double borderRadius(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? (mobile * 1.1);
    } else {
      return desktop ?? tablet ?? (mobile * 1.2);
    }
  }

  /// Get responsive column count for grid layouts
  static int columnCount(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? (mobile * 2);
    } else {
      return desktop ?? tablet ?? (mobile * 3);
    }
  }

  /// Get safe area based responsive padding
  static EdgeInsets safeAreaPadding(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;
    final screenWidth = MediaQuery.of(context).size.width;
    
    double horizontal = 16.0;
    if (screenWidth >= _tabletBreakpoint) {
      horizontal = 24.0;
    } else if (screenWidth >= _desktopBreakpoint) {
      horizontal = 32.0;
    }
    
    return EdgeInsets.only(
      left: horizontal + safePadding.left,
      right: horizontal + safePadding.right,
      top: safePadding.top,
      bottom: safePadding.bottom,
    );
  }

  /// Get maximum width for content (useful for desktop layouts)
  static double maxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth >= _desktopBreakpoint) {
      return 1200.0;
    } else if (screenWidth >= _tabletBreakpoint) {
      return 800.0;
    } else {
      return screenWidth;
    }
  }

  /// Create responsive widget based on screen size
  static Widget responsive(
    BuildContext context, {
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < _mobileBreakpoint) {
      return mobile;
    } else if (screenWidth < _tabletBreakpoint) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }
}
