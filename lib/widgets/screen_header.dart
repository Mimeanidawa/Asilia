import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'circle_back_button.dart';

/// Unified frosted header for drill-in screens.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
    this.backgroundColor,
    this.showBottomBorder = false,
    this.titleStyle,
    this.subtitleStyle,
    this.padding,
  });

  final String title;
  final VoidCallback onBack;
  final String? subtitle;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool showBottomBorder;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final EdgeInsetsGeometry? padding;

  static const _titleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.forest,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const _subtitleStyle = TextStyle(
    fontSize: 12,
    color: AppColors.gray500,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: backgroundColor == null ? AppColors.headerSheen : null,
        color: backgroundColor,
        boxShadow: showBottomBorder ? AppColors.elevationSm : null,
        border: Border(
          bottom: BorderSide(
            color: AppColors.forest.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(12, 10, 14, 12),
        child: Row(
          children: [
            CircleBackButton(onPressed: onBack),
            const SizedBox(width: 12),
            Expanded(
              child: subtitle == null
                  ? Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle ?? _titleStyle,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle ?? _titleStyle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle ?? _subtitleStyle,
                        ),
                      ],
                    ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
