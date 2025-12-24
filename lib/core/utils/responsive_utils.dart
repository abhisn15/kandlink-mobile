import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  // Get screen type based on width
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.mobile;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getScreenType(context) == ScreenType.tablet;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return getScreenType(context) == ScreenType.desktop;
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
        return const EdgeInsets.all(24);
      case ScreenType.desktop:
        return const EdgeInsets.all(32);
    }
  }

  // Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(8);
      case ScreenType.tablet:
        return const EdgeInsets.all(12);
      case ScreenType.desktop:
        return const EdgeInsets.all(16);
    }
  }

  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenType = getScreenType(context);
    final width = MediaQuery.of(context).size.width;

    // Scale factor based on screen width
    final scaleFactor = width / 375; // iPhone 6/7/8 width as base

    // Limit scaling for very small or very large screens
    final clampedScale = scaleFactor.clamp(0.8, 1.5);

    switch (screenType) {
      case ScreenType.mobile:
        return baseSize * clampedScale;
      case ScreenType.tablet:
        return baseSize * clampedScale * 1.1;
      case ScreenType.desktop:
        return baseSize * clampedScale * 1.2;
    }
  }

  // Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseSize;
      case ScreenType.tablet:
        return baseSize * 1.2;
      case ScreenType.desktop:
        return baseSize * 1.4;
    }
  }

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseSpacing;
      case ScreenType.tablet:
        return baseSpacing * 1.5;
      case ScreenType.desktop:
        return baseSpacing * 2;
    }
  }

  // Get responsive card elevation
  static double getResponsiveElevation(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 2;
      case ScreenType.tablet:
        return 4;
      case ScreenType.desktop:
        return 6;
    }
  }

  // Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return baseRadius;
      case ScreenType.tablet:
        return baseRadius * 1.2;
      case ScreenType.desktop:
        return baseRadius * 1.5;
    }
  }

  // Get responsive grid columns
  static int getResponsiveGridColumns(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return 2;
      case ScreenType.tablet:
        return 3;
      case ScreenType.desktop:
        return 4;
    }
  }

  // Get responsive max width for content
  static double? getResponsiveMaxWidth(BuildContext context) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.mobile:
        return null; // Full width
      case ScreenType.tablet:
        return 600;
      case ScreenType.desktop:
        return 800;
    }
  }

  // Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // Get responsive container width
  static double getResponsiveContainerWidth(BuildContext context, double maxWidth) {
    final width = MediaQuery.of(context).size.width;
    final padding = getResponsivePadding(context);
    final availableWidth = width - padding.left - padding.right;
    return availableWidth < maxWidth ? availableWidth : maxWidth;
  }

  // Get responsive dialog width
  static double getResponsiveDialogWidth(BuildContext context) {
    final screenType = getScreenType(context);
    final width = MediaQuery.of(context).size.width;

    switch (screenType) {
      case ScreenType.mobile:
        return width * 0.9;
      case ScreenType.tablet:
        return width * 0.7;
      case ScreenType.desktop:
        return width * 0.5;
    }
  }

  // Get responsive bottom sheet height
  static double getResponsiveBottomSheetHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final screenType = getScreenType(context);

    switch (screenType) {
      case ScreenType.mobile:
        return height * 0.8;
      case ScreenType.tablet:
        return height * 0.6;
      case ScreenType.desktop:
        return height * 0.5;
    }
  }
}

enum ScreenType {
  mobile,
  tablet,
  desktop,
}

// Extension methods for easier usage
extension ResponsiveExtensions on BuildContext {
  ScreenType get screenType => ResponsiveUtils.getScreenType(this);
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  bool get isPortrait => ResponsiveUtils.isPortrait(this);

  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);
  EdgeInsets get responsiveMargin => ResponsiveUtils.getResponsiveMargin(this);

  double responsiveFontSize(double baseSize) => ResponsiveUtils.getResponsiveFontSize(this, baseSize);
  double responsiveIconSize(double baseSize) => ResponsiveUtils.getResponsiveIconSize(this, baseSize);
  double responsiveSpacing(double baseSpacing) => ResponsiveUtils.getResponsiveSpacing(this, baseSpacing);
  double responsiveElevation() => ResponsiveUtils.getResponsiveElevation(this);
  double responsiveBorderRadius(double baseRadius) => ResponsiveUtils.getResponsiveBorderRadius(this, baseRadius);
  int get responsiveGridColumns => ResponsiveUtils.getResponsiveGridColumns(this);
  double? get responsiveMaxWidth => ResponsiveUtils.getResponsiveMaxWidth(this);

  double responsiveContainerWidth(double maxWidth) => ResponsiveUtils.getResponsiveContainerWidth(this, maxWidth);
  double get responsiveDialogWidth => ResponsiveUtils.getResponsiveDialogWidth(this);
  double get responsiveBottomSheetHeight => ResponsiveUtils.getResponsiveBottomSheetHeight(this);
}
