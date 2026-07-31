import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/admin_provider.dart';
import 'screens/analytics_screen.dart';
import 'screens/content_hub_screen.dart';
import 'screens/mwalimu_admin_screen.dart';
import 'screens/darasa_huru_admin_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/users_screen.dart';
import 'theme/admin_colors.dart';
import 'theme/admin_theme.dart';
import 'widgets/admin_bottom_nav.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: MaterialApp(
        title: 'Asilia Admin',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.dark,
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  void _onSplashDone() => setState(() => _showSplash = false);

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onDone: _onSplashDone);
    }

    final provider = context.watch<AdminProvider>();

    if (!provider.isLoggedIn) {
      return const LoginScreen();
    }

    return const _MainShell();
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final unread = provider.mwalimuUnreadCount;
    final showMaswaliFab = provider.activeScreen == AdminScreen.dashboard;

    final Widget screen;
    switch (provider.activeScreen) {
      case AdminScreen.dashboard:
        screen = const DashboardScreen();
      case AdminScreen.users:
        screen = const UsersScreen();
      case AdminScreen.analytics:
        screen = const AnalyticsScreen();
      case AdminScreen.notifications:
        screen = const NotificationsScreen();
      case AdminScreen.content:
        screen = const ContentHubScreen();
      case AdminScreen.darasaHuru:
        screen = const DarasaHuruAdminScreen();
      case AdminScreen.mwalimu:
        screen = const MwalimuAdminScreen();
      case AdminScreen.settings:
        screen = const SettingsScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1612),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(provider.activeScreen),
          child: screen,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: showMaswaliFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _MaswaliFab(
                unread: unread,
                onTap: () => provider.setScreen(AdminScreen.mwalimu),
              ),
            )
          : null,
      bottomNavigationBar: AdminBottomNav(
        current: provider.activeScreen,
        onTap: (screen) {
          // Maswali is FAB-only — keep Settings/Dashboard etc.
          if (screen == AdminScreen.mwalimu) return;
          provider.setScreen(screen);
        },
      ),
    );
  }
}

class _MaswaliFab extends StatelessWidget {
  const _MaswaliFab({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AdminColors.forestLight, AdminColors.forest],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: AdminColors.emerald.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 26),
              if (unread > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    decoration: BoxDecoration(
                      color: AdminColors.error,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.bg, width: 2),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
