import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Accent colors for headings and callout message blocks.
class BlockAccentStyle {
  BlockAccentStyle._();

  static const accents = ['emerald', 'forest', 'amber', 'blue', 'purple', 'rose'];

  static const calloutVariants = [
    ('tip', 'Kidokezo', Icons.lightbulb_outline_rounded),
    ('info', 'Taarifa', Icons.info_outline_rounded),
    ('warning', 'Onyo', Icons.warning_amber_rounded),
    ('important', 'Muhimu', Icons.priority_high_rounded),
    ('wisdom', 'Hekima', Icons.auto_stories_rounded),
  ];

  static Color colorFor(String accent) => switch (accent) {
        'forest' => AppColors.forest,
        'amber' => const Color(0xFFD97706),
        'blue' => const Color(0xFF2563EB),
        'purple' => const Color(0xFF7C3AED),
        'rose' => const Color(0xFFE11D48),
        _ => AppColors.emerald700,
      };

  static String variantColorKey(String variant) => switch (variant) {
        'warning' => 'amber',
        'important' => 'rose',
        'wisdom' => 'purple',
        'info' => 'blue',
        _ => 'emerald',
      };

  static Color backgroundFor(String variant) => colorFor(variantColorKey(variant)).withValues(alpha: 0.1);

  static Color borderFor(String variant) => colorFor(variantColorKey(variant)).withValues(alpha: 0.35);

  static IconData iconForCallout(String variant) {
    for (final v in calloutVariants) {
      if (v.$1 == variant) return v.$3;
    }
    return Icons.chat_bubble_outline_rounded;
  }

  static String labelForCallout(String variant) {
    for (final v in calloutVariants) {
      if (v.$1 == variant) return v.$2;
    }
    return 'Ujumbe';
  }
}
