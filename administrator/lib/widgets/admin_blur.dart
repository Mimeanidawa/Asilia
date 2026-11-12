import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';

/// Frosted strip used behind app bars so the active header stays in focus.
class AdminBarBlur extends StatelessWidget {
  const AdminBarBlur({super.key, this.sigma = 18, this.tint});

  final double sigma;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tint ?? AdminColors.bg.withValues(alpha: 0.62),
            border: Border(
              bottom: BorderSide(
                color: AdminColors.cardBorder.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAdminDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => Center(child: builder(ctx)),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return Stack(
        fit: StackFit.expand,
        children: [
          _FocusScrim(
            animation: curved,
            onDismiss: barrierDismissible ? () => Navigator.of(ctx).pop() : null,
          ),
          FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

Future<T?> showAdminSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Color backgroundColor = AdminColors.surface,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool barrierDismissible = true,
  ShapeBorder? shape,
}) {
  final resolvedShape = shape ??
      (backgroundColor == Colors.transparent
          ? const RoundedRectangleBorder()
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ));

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) {
      final height = MediaQuery.sizeOf(ctx).height;
      Widget sheet = builder(ctx);
      if (useSafeArea) {
        sheet = SafeArea(top: false, child: sheet);
      }
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: height * (isScrollControlled ? 0.92 : 0.72),
          ),
          child: Material(
            color: backgroundColor,
            elevation: 0,
            shape: resolvedShape,
            clipBehavior: Clip.antiAlias,
            child: sheet,
          ),
        ),
      );
    },
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return Stack(
        fit: StackFit.expand,
        children: [
          _FocusScrim(
            animation: curved,
            onDismiss: barrierDismissible ? () => Navigator.of(ctx).pop() : null,
          ),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          ),
        ],
      );
    },
  );
}

class _FocusScrim extends StatelessWidget {
  const _FocusScrim({required this.animation, this.onDismiss});

  final Animation<double> animation;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16 * animation.value,
          sigmaY: 16 * animation.value,
        ),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.38 * animation.value),
        ),
      ),
    );
  }
}
