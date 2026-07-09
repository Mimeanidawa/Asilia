import 'package:flutter/material.dart';

/// Circular back control used across drill-in screens.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({
    super.key,
    required this.onPressed,
    this.size = 36,
    this.iconSize = 18,
  });

  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  static const _background = Color(0xFF537F00);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
