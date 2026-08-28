import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/remote_app_config_service.dart';
import '../theme/app_colors.dart';

class AppScreenMessageBanner extends StatelessWidget {
  const AppScreenMessageBanner({super.key});

  Color _bg(String style) {
    switch (style) {
      case 'warning':
        return const Color(0xFFFFF4E5);
      case 'success':
        return const Color(0xFFE8F5EE);
      default:
        return AppColors.emerald50;
    }
  }

  Color _accent(String style) {
    switch (style) {
      case 'warning':
        return AppColors.amber;
      case 'success':
        return AppColors.emerald700;
      default:
        return AppColors.forest;
    }
  }

  IconData _icon(String style) {
    switch (style) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<RemoteAppConfigService>();
    if (!remote.showScreenMessage) return const SizedBox.shrink();

    final msg = remote.screenMessage;
    final accent = _accent(msg.style);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Material(
        color: _bg(msg.style),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon(msg.style), color: accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msg.title.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          msg.title.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ),
                    Text(
                      msg.body.trim(),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forest.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (msg.dismissible)
                IconButton(
                  tooltip: 'Funga',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => remote.dismissScreenMessage(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.forest.withValues(alpha: 0.45),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
