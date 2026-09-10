import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';

/// Flat edge-to-edge tab bar (WhatsApp / X style) — no floating pill.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static const double barHeight = 56;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final mwalimu = context.watch<MwalimuService>();
    final active = app.activeScreen;
    final ulizaUnread = active == AppScreen.askExpert ? 0 : mwalimu.unreadCount;
    final isExploreActive =
        active == AppScreen.contentList || active == AppScreen.conditions;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: AppColors.surfaceElevated,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border(
            top: BorderSide(color: AppColors.forest.withValues(alpha: 0.08)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: barHeight,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Nyumbani',
                  selected: active == AppScreen.home,
                  onTap: () => app.navigate(AppScreen.home),
                ),
                _NavItem(
                  icon: Icons.menu_book_outlined,
                  selectedIcon: Icons.menu_book_rounded,
                  label: 'Jifunze',
                  selected: active == AppScreen.learn,
                  onTap: () => app.navigate(AppScreen.learn),
                ),
                _NavItem(
                  icon: Icons.spa_outlined,
                  selectedIcon: Icons.spa_rounded,
                  label: 'Makala',
                  selected: isExploreActive,
                  onTap: () {
                    app.selectedContentCategory = null;
                    app.navigate(
                      AppScreen.contentList,
                      contentSection: ContentSections.allMakala,
                    );
                  },
                ),
                _UlizaNavItem(
                  selected: active == AppScreen.askExpert,
                  unreadCount: ulizaUnread,
                  onTap: () => app.navigate(AppScreen.askExpert),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'Akaunti',
                  selected: active == AppScreen.profile,
                  onTap: () => app.navigate(AppScreen.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UlizaNavItem extends StatelessWidget {
  const _UlizaNavItem({
    required this.selected,
    required this.unreadCount,
    required this.onTap,
  });

  final bool selected;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;
    final color = hasUnread && !selected
        ? AppColors.amber
        : (selected
            ? AppColors.forest
            : AppColors.forest.withValues(alpha: 0.45));

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  _ShakingIcon(
                    enabled: hasUnread && !selected,
                    child: Icon(
                      selected
                          ? Icons.chat_bubble_rounded
                          : (hasUnread
                              ? Icons.mark_chat_unread_rounded
                              : Icons.chat_bubble_outline_rounded),
                      size: 24,
                      color: color,
                    ),
                  ),
                  if (hasUnread)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: _UnreadDot(count: unreadCount),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Uliza',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected || hasUnread
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.forest
        : AppColors.forest.withValues(alpha: 0.45);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShakingIcon extends StatefulWidget {
  const _ShakingIcon({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<_ShakingIcon> createState() => _ShakingIconState();
}

class _ShakingIconState extends State<_ShakingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _ShakingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final wave = math.sin(_controller.value * math.pi * 4);
          return Transform.rotate(
            angle: widget.enabled ? wave * 0.12 : 0,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.1,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(
          begin: 0.85,
          end: 1,
          duration: 1200.ms,
        );
  }
}
