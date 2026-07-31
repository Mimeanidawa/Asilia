import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Green verified badge shown on makala the user has already paid for.
class PaidMakalaBadge extends StatelessWidget {
  const PaidMakalaBadge({
    super.key,
    this.compact = false,
    this.onDark = false,
  });

  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFFECFDF5);
    final fg = AppColors.emerald700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: compact ? 11 : 13,
            color: fg,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            'Umelipia',
            style: TextStyle(
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
