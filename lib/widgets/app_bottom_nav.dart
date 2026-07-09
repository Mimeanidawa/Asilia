import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';

const _navRadius = 30.0;
const _goldBadge = Color(0xFFD4A017);

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final mwalimu = context.watch<MwalimuService>();
    final active = app.activeScreen;
    final ulizaUnread = active == AppScreen.askExpert ? 0 : mwalimu.unreadCount;
    final isExploreActive = active == AppScreen.contentList || active == AppScreen.conditions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(_navRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Nyumbani',
            selected: active == AppScreen.home,
            onTap: () => app.navigate(AppScreen.home),
          ),
          _NavItem(
            icon: Icons.menu_book_rounded,
            label: 'Jifunze',
            selected: active == AppScreen.learn,
            onTap: () => app.navigate(AppScreen.learn),
          ),
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Material(
                  color: isExploreActive ? AppColors.amber : AppColors.emerald50,
                  borderRadius: BorderRadius.circular(_navRadius),
                  elevation: isExploreActive ? 8 : 5,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(_navRadius),
                    onTap: () => app.navigate(
                      AppScreen.contentList,
                      contentSection: ContentSections.chaguaMada,
                      contentCategory: 'mimea',
                    ),
                    child: Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      child: AnimatedScale(
                        scale: isExploreActive ? 1.07 : 1,
                        duration: 220.ms,
                        curve: Curves.easeOutBack,
                        child: Icon(
                          Icons.eco_rounded,
                          color: isExploreActive ? Colors.white : AppColors.forest,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _UlizaNavItem(
            selected: active == AppScreen.askExpert,
            unreadCount: ulizaUnread,
            onTap: () => app.navigate(AppScreen.askExpert),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Mtumiaji',
            selected: active == AppScreen.profile,
            onTap: () => app.navigate(AppScreen.profile),
          ),
        ],
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
    final activeColor = AppColors.cream;
    final inactiveColor = Colors.white.withValues(alpha: 0.56);
    final iconColor = selected ? activeColor : inactiveColor;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_navRadius),
          child: AnimatedContainer(
            duration: 240.ms,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withValues(alpha: 0.12)
                  : hasUnread
                      ? _goldBadge.withValues(alpha: 0.14)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(_navRadius),
              border: Border.all(
                color: hasUnread && !selected
                    ? _goldBadge.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                          hasUnread
                              ? Icons.mark_chat_unread_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 19,
                          color: hasUnread && !selected ? _goldBadge : iconColor,
                        ),
                      ),
                      if (hasUnread)
                        Positioned(
                          top: -7,
                          right: -10,
                          child: _PulsingUnreadBadge(count: unreadCount),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Uliza',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: selected || hasUnread ? FontWeight.w900 : FontWeight.w600,
                    color: hasUnread && !selected ? _goldBadge : (selected ? activeColor : inactiveColor),
                    letterSpacing: selected ? 0.2 : 0,
                  ),
                ),
              ],
            ),
          ),
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

class _ShakingIconState extends State<_ShakingIcon> with SingleTickerProviderStateMixin {
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

class _PulsingUnreadBadge extends StatefulWidget {
  const _PulsingUnreadBadge({required this.count});

  final int count;

  @override
  State<_PulsingUnreadBadge> createState() => _PulsingUnreadBadgeState();
}

class _PulsingUnreadBadgeState extends State<_PulsingUnreadBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          return Opacity(
            opacity: 0.82 + (_pulse.value * 0.18),
            child: child,
          );
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF0C14A), _goldBadge],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _goldBadge.withValues(alpha: 0.55),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            widget.count > 99 ? '99+' : '${widget.count}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.cream;
    final inactiveColor = Colors.white.withValues(alpha: 0.56);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_navRadius),
          child: AnimatedContainer(
            duration: 240.ms,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(_navRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: selected ? activeColor : inactiveColor,
                      ),
                      if (badgeCount > 0)
                        Positioned(
                          top: -7,
                          right: -10,
                          child: SizedBox(
                            width: 22,
                            height: 18,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.amber,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.amber.withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                badgeCount > 99 ? '99+' : '$badgeCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    color: selected ? activeColor : inactiveColor,
                    letterSpacing: selected ? 0.2 : 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
