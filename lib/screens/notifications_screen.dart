import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/notification_center_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../widgets/pull_to_refresh.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Sasa hivi';
    if (diff.inHours < 1) return 'Dakika ${diff.inMinutes} zilizopita';
    if (diff.inDays < 1) return 'Saa ${diff.inHours} zilizopita';
    if (diff.inDays < 7) return 'Siku ${diff.inDays} zilizopita';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'lesson':
        return Icons.school_rounded;
      case 'article':
        return Icons.article_rounded;
      case 'welcome':
        return Icons.eco_rounded;
      case 'mwalimu':
        return Icons.school_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'lesson':
        return AppColors.emerald800;
      case 'article':
        return AppColors.forest;
      case 'welcome':
        return AppColors.forest;
      case 'mwalimu':
        return const Color(0xFF1E40AF);
      case 'message':
        return AppColors.blue900;
      default:
        return AppColors.amber;
    }
  }

  void _onTap(BuildContext context, AppNotification n) {
    final center = context.read<NotificationCenterService>();
    final app = context.read<AppProvider>();
    center.markRead(n.id);

    final hasTarget = n.contentId != null || n.lessonId != null || n.type == 'message';
    if (!hasTarget) return;

    app.openFromNotification(
      lessonId: n.lessonId,
      contentId: n.contentId,
      type: n.type,
    );
  }

  bool _hasTarget(AppNotification n) =>
      n.contentId != null || n.lessonId != null || n.type == 'message';

  @override
  Widget build(BuildContext context) {
    final center = context.watch<NotificationCenterService>();
    final items = center.items;

    return SizedBox.expand(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.read<AppProvider>().goBack(),
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.forest, size: 18),
                ),
                const Expanded(
                  child: Text(
                    'ARIFA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                    ),
                  ),
                ),
                if (center.unreadCount > 0)
                  TextButton(
                    onPressed: center.markAllRead,
                    child: const Text(
                      'Soma zote',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.emerald800),
                    ),
                  ),
              ],
            ),
          ),
          if (center.unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: AppColors.amber.withValues(alpha: 0.08),
              child: Text(
                'Una arifa ${center.unreadCount} ambazo hazijasomwa',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amber),
              ),
            ),
          Expanded(
            child: PullToRefresh(
              onRefresh: () => AppRefresh.notifications(context),
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.45,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.gray400),
                              const SizedBox(height: 12),
                              Text('Hakuna arifa bado', style: TextStyle(color: AppColors.gray400, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                      final n = items[i];
                      final color = _colorFor(n.type);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: n.isRead ? Colors.white : AppColors.emerald50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _hasTarget(n) ? () => _onTap(context, n) : null,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: n.isRead
                                      ? AppColors.forest.withValues(alpha: 0.06)
                                      : AppColors.forest.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_iconFor(n.type), color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900,
                                                  color: AppColors.forest,
                                                ),
                                              ),
                                            ),
                                            if (!n.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.amber,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n.body,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray500,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _formatTime(n.timestamp),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.gray400,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_hasTarget(n))
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4, top: 8),
                                      child: Icon(Icons.chevron_right_rounded, color: AppColors.gray400, size: 20),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.03),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
