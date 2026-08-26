import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'circle_back_button.dart';

/// Centered title bar with back button on the left and optional trailing actions.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
    this.backgroundColor = AppColors.surfaceElevated,
    this.showBottomBorder = false,
    this.titleStyle,
    this.subtitleStyle,
    this.padding,
  });

  final String title;
  final VoidCallback onBack;
  final String? subtitle;
  final Widget? trailing;
  final Color backgroundColor;
  final bool showBottomBorder;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final EdgeInsetsGeometry? padding;

  static const _titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.forest,
    letterSpacing: -0.3,
  );

  static const _subtitleStyle = TextStyle(
    fontSize: 11,
    color: AppColors.gray500,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(8, 10, 12, 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: showBottomBorder ? AppColors.elevationSm : null,
        border: showBottomBorder
            ? null
            : Border(
                bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.04)),
              ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CircleBackButton(onPressed: onBack),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: subtitle == null
                ? Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle ?? _titleStyle,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle ?? _titleStyle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: subtitleStyle ?? _subtitleStyle,
                      ),
                    ],
                  ),
          ),
          if (trailing != null)
            Align(
              alignment: Alignment.centerRight,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
