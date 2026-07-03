import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.current,
    required this.onTap,
  });

  final AdminScreen current;
  final void Function(AdminScreen) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.cardBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                screen: AdminScreen.dashboard,
                current: current,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'Users',
                screen: AdminScreen.users,
                current: current,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Analytics',
                screen: AdminScreen.analytics,
                current: current,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.notifications_rounded,
                label: 'Notify',
                screen: AdminScreen.notifications,
                current: current,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.auto_stories_rounded,
                label: 'Content',
                screen: AdminScreen.content,
                current: current,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.school_rounded,
                label: 'Darasa',
                screen: AdminScreen.darasaHuru,
                current: current,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.medical_services_rounded,
                label: 'Mwalimu',
                screen: AdminScreen.mwalimu,
                current: current,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                screen: AdminScreen.settings,
                current: current,
                onTap: onTap,
              ),
            ],
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
    required this.screen,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AdminScreen screen;
  final AdminScreen current;
  final void Function(AdminScreen) onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = screen == current;
    return GestureDetector(
      onTap: () => onTap(screen),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AdminColors.emeraldGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isActive),
                color: isActive ? AdminColors.emerald : AdminColors.textDim,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AdminColors.emerald : AdminColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
