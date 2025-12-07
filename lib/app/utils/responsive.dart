import 'package:flutter/material.dart';

/// Responsive layout utilities for adaptive UI
class Responsive {
  /// Get responsive horizontal padding based on screen width
  /// Returns smaller padding on smaller screens to prevent overflow
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 1300) {
      return 16.0; // Smaller padding for smaller windows
    } else if (width < 1600) {
      return 24.0; // Medium padding
    } else {
      return 32.0; // Full padding for large windows
    }
  }

  /// Get responsive vertical padding
  static double verticalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 1300) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  /// Get responsive edge insets for symmetric horizontal padding
  static EdgeInsets horizontalPaddingInsets(BuildContext context) {
    return EdgeInsets.symmetric(horizontal: horizontalPadding(context));
  }

  /// Get responsive edge insets for all padding
  static EdgeInsets allPaddingInsets(BuildContext context) {
    final padding = horizontalPadding(context);
    return EdgeInsets.all(padding);
  }

  /// Check if screen is small (less than 1300px width)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 1300;
  }

  /// Check if screen is medium (1300-1600px width)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1300 && width < 1600;
  }

  /// Check if screen is large (1600px+ width)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1600;
  }

  /// Get responsive column spacing
  static double columnSpacing(BuildContext context) {
    if (isSmallScreen(context)) {
      return 16.0;
    } else {
      return 24.0;
    }
  }

  /// Get responsive row spacing
  static double rowSpacing(BuildContext context) {
    if (isSmallScreen(context)) {
      return 16.0;
    } else {
      return 24.0;
    }
  }
}

