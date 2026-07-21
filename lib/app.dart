import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      _notificationService.onNotificationTap = ({lessonId, contentId, type}) {
        _appProvider.openFromNotification(
          lessonId: lessonId,
          contentId: contentId,
          type: type,
        );
      };
      _notificationService.onPushReceived = ({
        required title,
        required body,
        lessonId,
        contentId,
        type,
      }) {
        if (type == 'message') {
          _mwalimuService.handleIncomingAdminPush();
          if (_userService.token != null) {
            _mwalimuService.syncMessages(_userService.token);
          } else {
            _mwalimuService.loadGuestMessages();
          }
        }
        _notificationCenter.addFromPush(
          title: title.isNotEmpty ? title : 'Ujumbe kutoka kwa Mwalimu',
          body: body.isNotEmpty ? body : 'Una ujumbe mpya katika Uliza Mwalimu',
          lessonId: lessonId,
          contentId: contentId,
          type: type,
        );
      };
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }

    await Future.wait([
      _loadUserAndMwalimu(),
      _contentService.load(),
      _appProvider.init(),
    ]);
    await _notificationCenter.syncFromCatalog(
      posts: [
        ..._contentService.dodosoPosts,
        ..._contentService.chaguaMadaPosts,
        ..._contentService.vyakulaMatundaPosts,
        ..._contentService.jifunzePosts,
      ],
      lessons: _lessonService.publishedLessons,
    );

    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadUserAndMwalimu() async {
    await _userService.load();
    await _notificationService.linkToUser(_userService.token);
    await _mwalimuService.loadSettings();
    await _mwalimuService.loadGuestState();
    if (_userService.token != null) {
      await _mwalimuService.flushGuestMessagesToServer(_userService.token!);
      await _mwalimuService.syncMessages(_userService.token);
    } else {
      await _mwalimuService.loadGuestMessages();
    }
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
        Provider<NotificationService>.value(value: _notificationService),
      ],
      child: MaterialApp(
        title: 'Dawa Asili',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
        ),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(mq.textScaler.scale(1) * 1.1),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: _ready ? const _AppShell() : const AppLoadingSkeleton(),
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
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final user = context.read<UserService>();
    final mwalimu = context.read<MwalimuService>();
    if (user.token != null) {
      mwalimu.syncMessages(user.token);
    } else {
      mwalimu.loadGuestMessages();
    }
  }

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
        screen = const ProfileScreen(key: ValueKey('profile-screen'));
      case AppScreen.darasaHuru:
        screen = DarasaHuruScreen(key: ValueKey(app.selectedLessonId));
      case AppScreen.contentList:
        screen = const ContentListScreen();
      case AppScreen.contentDetail:
        screen = ContentDetailScreen(key: ValueKey(app.selectedContentId));
      case AppScreen.auth:
        screen = const AuthScreen();
      case AppScreen.notifications:
        screen = const NotificationsScreen();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress(context, app);
      },
      child: AppScaffold(
        showBottomNav: app.showsBottomNav,
        child: screen,
      ),
    );
  }

  void _handleBackPress(BuildContext context, AppProvider app) {
    if (!app.isAtHome) {
      app.goBack();
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Bonyeza tena kurudi nyuma ili kufunga programu',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }
}
