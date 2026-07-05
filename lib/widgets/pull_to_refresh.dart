import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wraps scrollable content with pull-to-refresh using always-scrollable physics.
class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: color ?? AppColors.forest,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
