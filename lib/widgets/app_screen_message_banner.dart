import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

Future<void> maybeShowForceUpdateDialog(BuildContext context) async {
  final remote = context.read<RemoteAppConfigService>();
  if (!remote.needsUpdate) return;
  if (!context.mounted) return;

  remote.markUpdateDialogShown();
  final update = remote.update;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.system_update_rounded,
                color: AppColors.forest,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                update.title.isNotEmpty ? update.title : 'Sasisha programu',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.forest,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          update.message.isNotEmpty
              ? update.message
              : 'Toleo jipya linahitajika ili uendelee kutumia Dawa Asili.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: AppColors.forest.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => openPlayStore(update.storeUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text(
                'Sasisha kwenye Play Store',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> openPlayStore(String storeUrl) async {
  final uri = Uri.tryParse(
    storeUrl.trim().isEmpty
        ? 'https://play.google.com/store/apps/details?id=com.asilia'
        : storeUrl.trim(),
  );
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
