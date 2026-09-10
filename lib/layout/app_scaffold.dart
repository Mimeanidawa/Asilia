import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/app_bottom_nav.dart';

/// Full-screen shell with a fixed flat bottom tab bar.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.showBottomNav = true,
  });

  final Widget child;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final contentBottom = Responsive.bottomContentReserve(
      context,
      showBottomNav: showBottomNav,
    );

    final injected = media.copyWith(
      padding: media.padding.copyWith(
        bottom: showBottomNav ? contentBottom : media.viewPadding.bottom,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surfaceElevated,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.canvasGradient),
          child: MediaQuery(
            data: injected,
            child: Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: ResponsivePage(child: child),
                  ),
                ),
                if (showBottomNav) const AppBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
