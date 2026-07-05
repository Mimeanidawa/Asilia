import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';

class PullToRefresh extends StatelessWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AdminColors.emerald,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
