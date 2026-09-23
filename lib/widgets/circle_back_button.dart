import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable_scale.dart';

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
    return PressableScale(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppColors.elevationSm,
        ),
        child: Center(
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
