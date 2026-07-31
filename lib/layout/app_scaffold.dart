import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/app_bottom_nav.dart';

/// Full-screen shell with floating bottom navigation over scroll content.
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
    final bottomFloat = Responsive.bottomNavFloatOffset(context);
    final contentBottom = Responsive.bottomContentReserve(
      context,
      showBottomNav: showBottomNav,
    );
    final navMaxWidth = Responsive.bottomNavMaxWidth(context);
    final horizontalPad = Responsive.horizontalGutter(context).clamp(12.0, 28.0);

    // Content paints edge-to-edge under the floating nav; scrollables read this
    // padding so last items remain reachable.
    final injected = media.copyWith(
      padding: media.padding.copyWith(
        bottom: showBottomNav ? contentBottom : media.viewPadding.bottom,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.cream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        extendBody: true,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.canvasGradient),
          child: MediaQuery(
            data: injected,
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: SafeArea(
                      bottom: false,
                      child: ResponsivePage(child: child),
                    ),
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
                            padding: EdgeInsets.symmetric(horizontal: horizontalPad),
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
      ),
    );
  }
}
