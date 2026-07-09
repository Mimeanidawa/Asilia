import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/app_bottom_nav.dart';

/// Full-screen shell with bottom navigation and Material ancestor for text.
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
    final bottomFloat = Responsive.bottomNavFloatOffset(context);
    final contentBottom = Responsive.bottomContentReserve(
      context,
      showBottomNav: showBottomNav,
    );
    final navMaxWidth = Responsive.bottomNavMaxWidth(context);
    final horizontalPad = Responsive.horizontalGutter(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        systemNavigationBarColor: AppColors.cream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          bottom: false,
          child: Material(
            color: AppColors.cream,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  bottom: showBottomNav ? contentBottom : Responsive.viewPadding(context).bottom,
                  child: ResponsivePage(child: child),
                ),
                if (showBottomNav)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomFloat,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: navMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPad.clamp(10, 28)),
                          child: const AppBottomNav(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
