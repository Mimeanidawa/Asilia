import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_colors.dart';

class ConditionIconWidget extends StatelessWidget {
  const ConditionIconWidget({super.key, required this.type});

  final ConditionIconType type;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;

    switch (type) {
      case ConditionIconType.cough:
        icon = Icons.thermostat;
        color = Colors.red.shade600;
      case ConditionIconType.stomach:
        icon = Icons.monitor_heart_outlined;
        color = Colors.amber.shade600;
      case ConditionIconType.heart:
        icon = Icons.local_fire_department;
        color = Colors.pink.shade400;
      case ConditionIconType.diabetes:
        icon = Icons.shield_outlined;
        color = Colors.indigo.shade600;
      case ConditionIconType.skin:
        icon = Icons.verified_user_outlined;
        color = AppColors.emerald700;
    }

    return Icon(icon, size: 22, color: color);
  }
}
