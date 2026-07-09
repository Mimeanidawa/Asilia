import 'package:flutter/material.dart';

/// Layout breakpoints for phone → tablet → large screens.
class AppBreakpoints {
  static const double phone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

class Responsive {
  Responsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static EdgeInsets viewPadding(BuildContext context) =>
      MediaQuery.viewPaddingOf(context);

  static bool isPhone(BuildContext context) => width(context) < AppBreakpoints.phone;

  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= AppBreakpoints.phone && w < AppBreakpoints.desktop;
  }

  static bool isLarge(BuildContext context) => width(context) >= AppBreakpoints.desktop;

  /// Max width for primary page content (centered on wide screens).
  static double contentMaxWidth(BuildContext context) {
    final w = width(context);
    if (w >= AppBreakpoints.desktop) return 1100;
    if (w >= AppBreakpoints.tablet) return 920;
    if (w >= AppBreakpoints.phone) return 760;
    return w;
  }

  /// Floating bottom nav max width scales gently on tablets.
  static double bottomNavMaxWidth(BuildContext context) {
    final w = width(context);
    if (w >= AppBreakpoints.desktop) return 560;
    if (w >= AppBreakpoints.tablet) return 520;
    if (w >= AppBreakpoints.phone) return 480;
    return w - 20;
  }

  static double horizontalGutter(BuildContext context) {
    if (isLarge(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }

  /// Bottom offset for floating nav — clears 3-button / gesture system bars.
  static double bottomNavFloatOffset(BuildContext context) {
    return viewPadding(context).bottom + 10;
  }

  /// Space reserved above system navigation so content is never hidden.
  static double bottomContentReserve(
    BuildContext context, {
    required bool showBottomNav,
  }) {
    final safeBottom = viewPadding(context).bottom;
    if (!showBottomNav) return safeBottom + 8;

    const navBarHeight = 78.0;
    const floatGap = 10.0;
    const extraClearance = 8.0;
    return navBarHeight + floatGap + safeBottom + extraClearance;
  }

  static int listColumns(BuildContext context) {
    if (isLarge(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  static int categoryColumns(BuildContext context) {
    if (isLarge(context)) return 4;
    if (isTablet(context)) return 4;
    return 2;
  }

  static int pathwayColumns(BuildContext context) {
    if (isLarge(context)) return 5;
    if (isTablet(context)) return 3;
    return 1;
  }
}

/// Centers and constrains child content on tablets and desktops.
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}
