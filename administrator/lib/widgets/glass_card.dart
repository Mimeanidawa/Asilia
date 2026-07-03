import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = 16.0,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final LinearGradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient ??
              const LinearGradient(
                colors: [AdminColors.card, Color(0xFF0F1E17)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? AdminColors.cardBorder,
            width: borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AdminColors.emeraldGlow,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
