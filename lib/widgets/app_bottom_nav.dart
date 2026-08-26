import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';

const _navRadius = 26.0;

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final mwalimu = context.watch<MwalimuService>();
    final active = app.activeScreen;
    final ulizaUnread = active == AppScreen.askExpert ? 0 : mwalimu.unreadCount;
    final isExploreActive =
        active == AppScreen.contentList || active == AppScreen.conditions;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(_navRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Nyumbani',
            selected: active == AppScreen.home,
            onTap: () => app.navigate(AppScreen.home),
          ),
          _NavItem(
            icon: Icons.auto_stories_rounded,
            label: 'Jifunze',
            selected: active == AppScreen.learn,
            onTap: () => app.navigate(AppScreen.learn),
          ),
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -14),
                child: Material(
                  color: isExploreActive ? AppColors.amber : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  elevation: 8,
                  shadowColor: AppColors.forest.withValues(alpha: 0.35),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      app.selectedContentCategory = null;
                      app.navigate(
                        AppScreen.contentList,
                        contentSection: ContentSections.allMakala,
                      );
                    },
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.eco_rounded,
                        color: isExploreActive ? Colors.white : AppColors.forest,
                        size: 26,
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
            icon: Icons.person_rounded,
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
    final activeColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.55);
    final accent = const Color(0xFFE0B089);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_navRadius),
        child: AnimatedContainer(
          duration: 220.ms,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
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
                        size: 20,
                        color: hasUnread && !selected
                            ? accent
                            : (selected ? activeColor : inactiveColor),
                      ),
                    ),
                    if (hasUnread)
                      Positioned(
                        top: -6,
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
                  fontSize: 10,
                  fontWeight: selected || hasUnread ? FontWeight.w800 : FontWeight.w600,
                  color: hasUnread && !selected
                      ? accent
                      : (selected ? activeColor : inactiveColor),
                ),
              ),
            ],
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
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Opacity(
          opacity: 0.85 + (_pulse.value * 0.15),
          child: child,
        );
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Text(
          widget.count > 99 ? '99+' : '${widget.count}',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.55);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_navRadius),
        child: AnimatedContainer(
          duration: 220.ms,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
