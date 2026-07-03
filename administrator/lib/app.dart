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

    return _MainShell();
  }
}

class _MainShell extends StatelessWidget {
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
      bottomNavigationBar: AdminBottomNav(
        current: provider.activeScreen,
        onTap: provider.setScreen,
      ),
    );
  }
}
