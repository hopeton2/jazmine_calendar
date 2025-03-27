import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Helper class containing static methods for common UI operations
class UIHelper {
  
  static const kSmallDevice = 450;
  static const kMediumDevice = 700;
  static const kLargeDevice = 1400;
  static const double kMobileViewWidth = 767;
  
  /// Returns a semi-transparent version of the given color
  /// [color] The base color to make transparent
  /// [opacity] The opacity level (0.0 to 1.0), defaults to 0.3
  static Color getTransparentVersion(Color color, {double opacity = 0.3}) {
    return color.withOpacity(opacity);
  }

  /// Returns a darker version of the given color
  /// [color] The base color to darken
  /// [factor] How much to darken the color (0.0 to 1.0), defaults to 0.1
  static Color getDarkerVersion(Color color, {double factor = 0.1}) {
    assert(factor >= 0 && factor <= 1, 'Factor must be between 0.0 and 1.0');
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0)).toColor();
  }

  /// Returns a lighter version of the given color
  /// [color] The base color to lighten
  /// [factor] How much to lighten the color (0.0 to 1.0), defaults to 0.1
  static Color getLighterVersion(Color color, {double factor = 0.1}) {
    assert(factor >= 0 && factor <= 1, 'Factor must be between 0.0 and 1.0');
    final HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + factor).clamp(0.0, 1.0)).toColor();
  }

  /// Returns a color with adjusted opacity based on the current theme brightness
  /// [color] The base color
  /// [context] The build context
  /// [lightModeOpacity] Opacity for light mode, defaults to 0.3
  /// [darkModeOpacity] Opacity for dark mode, defaults to 0.4
  static Color getThemeAwareTransparency(
    Color color,
    BuildContext context, {
    double lightModeOpacity = 0.3,
    double darkModeOpacity = 0.4,
  }) {
    final brightness = Theme.of(context).brightness;
    return color.withOpacity(
      brightness == Brightness.light ? lightModeOpacity : darkModeOpacity,
    );
  }


  /// Determines if the current platform is a mobile device (iOS or Android)
  /// Returns false if running on web, regardless of platform
  /// [context] The build context used to determine the platform
  static bool isMobileLayout(BuildContext context) {
    if (kIsWeb) {
      // For web, determine based on screen width
      return MediaQuery.of(context).size.width <= kMobileViewWidth;
    }
    var platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  /// Determines if the UI should use mobile layout based on width and platform
  /// [context] The build context used to get screen dimensions
  static bool shouldUseMobileLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = isMobileLayout(context);
    return isMobile || width <= kMobileViewWidth;
  }

  /// Checks if the device screen width is less than or equal to [kSmallDevice]
  /// [context] The build context used to get screen dimensions
  static bool isSmallDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width <= kSmallDevice;
  }

  /// Checks if the device screen width is between [kSmallDevice] and [kMediumDevice]
  /// [context] The build context used to get screen dimensions
  static bool isMediumDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > kSmallDevice && width <= kMediumDevice;
  }

  /// Checks if the device screen width is greater than or equal to [kLargeDevice]
  /// [context] The build context used to get screen dimensions
  static bool isLargeDevice(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= kLargeDevice;
  }

  /// Gets the current device size category
  /// [context] The build context used to get screen dimensions
  static DeviceSize getDeviceSize(BuildContext context) {
    if (isSmallDevice(context)) return DeviceSize.small;
    if (isMediumDevice(context)) return DeviceSize.medium;
    if (isLargeDevice(context)) return DeviceSize.large;
    return DeviceSize.medium;
  }
}

/// Enum representing different device size categories
enum DeviceSize {
  small,
  medium,
  large
}

