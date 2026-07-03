import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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

  static const double _navHeight = 88;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Material(
          color: AppColors.cream,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                bottom: showBottomNav ? _navHeight : 0,
                child: child,
              ),
              if (showBottomNav)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AppBottomNav(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
