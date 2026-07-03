import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'layout/app_scaffold.dart';
import 'models/models.dart';
import 'providers/app_provider.dart';
import 'screens/ask_expert_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/conditions_screen.dart';
import 'screens/content_detail_screen.dart';
import 'screens/content_list_screen.dart';
import 'screens/herb_details_screen.dart';
import 'screens/darasa_huru_screen.dart';
import 'screens/home_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'services/chat_service.dart';
import 'services/content_service.dart';
import 'services/lesson_service.dart';
import 'services/mwalimu_service.dart';
import 'services/notification_center_service.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'widgets/shimmer_loading.dart';

class AsiliaApp extends StatefulWidget {
  const AsiliaApp({super.key});

  @override
  State<AsiliaApp> createState() => _AsiliaAppState();
}

class _AsiliaAppState extends State<AsiliaApp> {
  late final AppProvider _appProvider;
  late final LessonService _lessonService;
  late final ContentService _contentService;
  late final UserService _userService;
  late final MwalimuService _mwalimuService;
  late final NotificationCenterService _notificationCenter;
  late final NotificationService _notificationService;

  bool _ready = false;

  @override
  void initState() {
    super.initState();

    String? apiKey = const String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isEmpty) apiKey = null;

    final chatService = ChatService(apiKey: apiKey);
    _lessonService = LessonService();
    _contentService = ContentService();
    _userService = UserService();
    _mwalimuService = MwalimuService();
    _notificationCenter = NotificationCenterService();
    _notificationService = NotificationService();
    _appProvider = AppProvider(
      chatService: chatService,
      lessonService: _lessonService,
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _notificationCenter.load();

    try {
      await _notificationService.init();
      _notificationService.onNotificationTap = ({lessonId, contentId}) {
        _appProvider.openFromNotification(lessonId: lessonId, contentId: contentId);
      };
      _notificationService.onPushReceived = ({
        required title,
        required body,
        lessonId,
        contentId,
      }) {
        _notificationCenter.addFromPush(
          title: title,
          body: body,
          lessonId: lessonId,
          contentId: contentId,
        );
      };
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }

    await _userService.load();
    await _mwalimuService.loadSettings();
    await _contentService.load(userToken: _userService.token);
    await _appProvider.init();

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appProvider),
        ChangeNotifierProvider.value(value: _lessonService),
        ChangeNotifierProvider.value(value: _contentService),
        ChangeNotifierProvider.value(value: _userService),
        ChangeNotifierProvider.value(value: _mwalimuService),
        ChangeNotifierProvider.value(value: _notificationCenter),
      ],
      child: MaterialApp(
        title: 'Dawa Asili',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _ready ? const _AppShell() : const AppLoadingSkeleton(),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    if (!app.isLoaded) {
      return const AppLoadingSkeleton();
    }

    final Widget screen;
    switch (app.activeScreen) {
      case AppScreen.home:
        screen = const HomeScreen();
      case AppScreen.herbDetails:
        screen = const HerbDetailsScreen();
      case AppScreen.askExpert:
        screen = const AskExpertScreen();
      case AppScreen.learn:
        screen = const LearnScreen();
      case AppScreen.conditions:
        screen = const ConditionsScreen();
      case AppScreen.profile:
        screen = const ProfileScreen();
      case AppScreen.darasaHuru:
        screen = const DarasaHuruScreen();
      case AppScreen.contentList:
        screen = const ContentListScreen();
      case AppScreen.contentDetail:
        screen = const ContentDetailScreen();
      case AppScreen.auth:
        screen = const AuthScreen();
      case AppScreen.notifications:
        screen = const NotificationsScreen();
    }

    final hideNav = app.activeScreen == AppScreen.herbDetails ||
        app.activeScreen == AppScreen.auth;

    return AppScaffold(
      showBottomNav: !hideNav,
      child: screen,
    );
  }
}
