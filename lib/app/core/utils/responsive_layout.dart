import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../values/app_constants.dart';

enum DeviceScreenType { mobile, tablet, desktop }

/// Responsive utility widget and helper methods for Mobile (< 650px),
/// Tablet (650px - 1100px), and Desktop/Web (> 1100px).
class ResponsiveLayout extends StatelessWidget {
  final Widget? mobile;
  final Widget? tablet;
  final Widget? desktop;
  final WidgetBuilder? mobileBuilder;
  final WidgetBuilder? tabletBuilder;
  final WidgetBuilder? desktopBuilder;

  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  })  : assert(mobile != null || mobileBuilder != null, 'Either mobile or mobileBuilder must be provided'),
        assert(desktop != null || desktopBuilder != null, 'Either desktop or desktopBuilder must be provided');

  /// Check if current screen is Mobile (< 650px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;

  /// Check if current screen is Tablet (650px to 1100px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppConstants.mobileBreakpoint &&
        width <= AppConstants.tabletBreakpoint;
  }

  /// Check if current screen is Desktop / Large Web (> 1100px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > AppConstants.tabletBreakpoint;

  /// Check if the app is currently running on Web or Desktop
  static bool isWebOrDesktop(BuildContext context) =>
      kIsWeb || isDesktop(context);

  /// Determine the current DeviceScreenType
  static DeviceScreenType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > AppConstants.tabletBreakpoint) {
      return DeviceScreenType.desktop;
    } else if (width >= AppConstants.mobileBreakpoint) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.mobile;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > AppConstants.tabletBreakpoint) {
          if (desktopBuilder != null) return desktopBuilder!(context);
          return desktop!;
        } else if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          if (tabletBuilder != null) return tabletBuilder!(context);
          if (tablet != null) return tablet!;
          if (mobileBuilder != null) return mobileBuilder!(context);
          return mobile!;
        } else {
          if (mobileBuilder != null) return mobileBuilder!(context);
          return mobile!;
        }
      },
    );
  }
}

/// Generic ResponsiveBuilder for flexible inline responsive calculations
typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
  DeviceScreenType screenType,
);

class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final DeviceScreenType type;
        if (constraints.maxWidth > AppConstants.tabletBreakpoint) {
          type = DeviceScreenType.desktop;
        } else if (constraints.maxWidth >= AppConstants.mobileBreakpoint) {
          type = DeviceScreenType.tablet;
        } else {
          type = DeviceScreenType.mobile;
        }
        return builder(context, constraints, type);
      },
    );
  }
}
