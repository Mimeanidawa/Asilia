import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../services/notification_center_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../widgets/herb_image.dart';
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

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final center = context.read<NotificationCenterService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa arifa zote?'),
        content: const Text('Arifa zote zitafutwa kabisa kutoka kwenye kifaa chako.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Futa zote',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await center.clearAll();
  }

  Future<void> _confirmDeleteOne(BuildContext context, AppNotification n) async {
    final center = context.read<NotificationCenterService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa arifa?'),
        content: Text('Una uhakika unataka kufuta "${n.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ghairi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Futa',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await center.delete(n.id);
  }

  bool _hasTarget(AppNotification n) =>
      n.contentId != null || n.lessonId != null || n.type == 'message';

  String? _resolveImageUrl(BuildContext context, AppNotification n) {
    if (n.imageUrl.isNotEmpty) return n.imageUrl;

    final content = context.read<ContentService>();
    if (n.contentId != null) {
      for (final post in [
        ...content.chaguaMadaPosts,
        ...content.dodosoPosts,
        ...content.vyakulaMatundaPosts,
        ...content.jifunzePosts,
      ]) {
        if (post.id == n.contentId && post.imageUrl.isNotEmpty) {
          return post.imageUrl;
        }
      }
    }

    if (n.lessonId != null) {
      final lesson = context.read<AppProvider>().lessonService.lessonById(n.lessonId!);
      if (lesson != null && lesson.imageUrl.isNotEmpty) return lesson.imageUrl;
    }

    return null;
  }

  Widget _leadingVisual(BuildContext context, AppNotification n, Color color) {
    final imageUrl = _resolveImageUrl(context, n);
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HerbImage(
          url: imageUrl,
          width: 72,
          height: 72,
          borderRadius: 12,
        ),
      );
    }

    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_iconFor(n.type), color: color, size: 28),
    );
  }

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
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: () => _confirmDeleteAll(context),
                    child: const Text(
                      'Futa zote',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red),
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
                        child: Dismissible(
                          key: ValueKey(n.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 22),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          onDismissed: (_) => center.delete(n.id),
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
                                    _leadingVisual(context, n, color),
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
                                    IconButton(
                                      onPressed: () => _confirmDeleteOne(context, n),
                                      icon: Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.gray400.withValues(alpha: 0.8),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      tooltip: 'Futa',
                                    ),
                                    if (_hasTarget(n))
                                      const Padding(
                                        padding: EdgeInsets.only(left: 2, top: 8),
                                        child: Icon(Icons.chevron_right_rounded, color: AppColors.gray400, size: 20),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.03);
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
