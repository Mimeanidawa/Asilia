import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'widgets/admin_ui.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProvider(),
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: MaterialApp(
          title: 'Asilia Admin',
          debugShowCheckedModeBanner: false,
          theme: AdminTheme.dark,
          home: const _AppShell(),
        ),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WidgetsBindingObserver {
  bool _showSplash = true;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final provider = context.read<AdminProvider>();
    if (provider.isLoggedIn) {
      unawaited(provider.refreshPushRegistration());
    }
  }

  void _onSplashDone() => setState(() => _showSplash = false);

  void _handleBackPress(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final provider = context.read<AdminProvider>();
    if (provider.isLoggedIn && provider.activeScreen != AdminScreen.dashboard) {
      provider.setScreen(AdminScreen.dashboard);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.isLoggedIn
                ? 'Bonyeza tena kurudi nyuma ili kufunga programu'
                : 'Bonyeza tena ili kutoka',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AdminColors.card,
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onDone: _onSplashDone);
    }

    final provider = context.watch<AdminProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress(context);
      },
      child: provider.isLoggedIn ? const _MainShell() : const LoginScreen(),
    );
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

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

    return AdminBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(provider.activeScreen),
            child: screen,
          ),
        ),
        bottomNavigationBar: AdminBottomNav(
          current: provider.activeScreen,
          mwalimuUnread: provider.mwalimuUnreadCount,
          onTap: provider.setScreen,
        ),
      ),
    );
  }
}
