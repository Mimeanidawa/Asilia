import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft circular back control for drill-in screens.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({
    super.key,
    required this.onPressed,
    this.size = 40,
    this.iconSize = 18,
  });

  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.emerald50,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: AppColors.emerald200.withValues(alpha: 0.45),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: iconSize,
            color: AppColors.forest,
          ),
        ),
      ),
    );
  }
}
