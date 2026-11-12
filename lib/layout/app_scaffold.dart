import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/app_bottom_nav.dart';

/// Full-screen shell with the bottom navigation bar.
///
/// When [immersiveTop] is true (home) the child draws under the status bar
/// itself (e.g. a green brand header) and the status icons turn light.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.showBottomNav = true,
    this.immersiveTop = false,
  });

  final Widget child;
  final bool showBottomNav;
  final bool immersiveTop;

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

    final page = ResponsivePage(child: child);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (immersiveTop
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            immersiveTop ? Brightness.light : Brightness.dark,
        statusBarBrightness: immersiveTop ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            showBottomNav ? AppColors.surfaceElevated : AppColors.cream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: MediaQuery(
          data: injected,
          child: Column(
            children: [
              Expanded(
                child: immersiveTop
                    ? page
                    : SafeArea(bottom: false, child: page),
              ),
              if (showBottomNav)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.bottomNavMaxWidth(context),
                    ),
                    child: const AppBottomNav(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
