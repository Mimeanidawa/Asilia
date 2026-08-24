import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/admin_config.dart';
import '../firebase_options.dart';
import 'api_client.dart';

typedef AdminPushTapHandler = void Function();

const adminChannelId = 'asilia_admin';
const adminChannelName = 'Maswali — Admin';

AdminPushTapHandler? _globalTapHandler;
bool _fcmBootstrapped = false;
bool _topicSubscribed = false;

Future<void> _ensureAdminFirebase() async {
  if (!DefaultFirebaseOptions.isSupported) return;
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

bool get _isMobilePushPlatform =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

InitializationSettings _adminInitSettings() => const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
    );

NotificationDetails _adminNotificationDetails() => const NotificationDetails(
      android: AndroidNotificationDetails(
        adminChannelId,
        adminChannelName,
        channelDescription: 'Taarifa za maswali mapya kutoka watumiaji',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      linux: LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.critical,
        defaultActionName: 'Open',
      ),
    );

Future<void> _ensureAndroidChannel(FlutterLocalNotificationsPlugin local) async {
  if (kIsWeb || !Platform.isAndroid) return;
  const channel = AndroidNotificationChannel(
    adminChannelId,
    adminChannelName,
    description: 'Taarifa za maswali mapya kutoka watumiaji',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  await local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

Future<FlutterLocalNotificationsPlugin?> _pluginWithChannel() async {
  try {
    final local = FlutterLocalNotificationsPlugin();
    await local.initialize(
      settings: _adminInitSettings(),
      onDidReceiveNotificationResponse: (_) => _globalTapHandler?.call(),
    );
    await _ensureAndroidChannel(local);
    if (!kIsWeb && Platform.isAndroid) {
      await local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    return local;
  } catch (e) {
    debugPrint('Admin local notifications unavailable: $e');
    return null;
  }
}

String _safeAlertBody(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) return 'New message from user';
  return trimmed;
}

Future<void> showAdminLocalAlert({
  required String title,
  required String body,
  FlutterLocalNotificationsPlugin? plugin,
}) async {
  final local = plugin ?? await _pluginWithChannel();
  if (local == null) return;

  try {
    await local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title.trim().isEmpty ? 'Ujumbe mpya' : title.trim(),
      body: _safeAlertBody(body),
      notificationDetails: _adminNotificationDetails(),
      payload: jsonEncode({'type': 'admin_message'}),
    );
  } catch (e) {
    debugPrint('Admin local alert failed: $e');
  }
}

/// Must be registered from main() before runApp.
@pragma('vm:entry-point')
Future<void> adminFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AdminConfig.hasFirebase) return;
  try {
    await _ensureAdminFirebase();
  } catch (_) {}

  debugPrint('Admin background FCM: ${message.messageId}');

  // Ensure channel exists in the background isolate (required on some Android builds).
  await _pluginWithChannel();

  final title = message.notification?.title ??
      message.data['title'] as String? ??
      'Ujumbe mpya';
  final body = message.notification?.body ??
      message.data['body'] as String? ??
      'New message from user';

  // When the app is killed, Android usually shows notification-payload messages
  // automatically. Still show a local alert as a fallback on OEMs that skip it.
  if (message.notification != null && Platform.isAndroid) {
    return;
  }

  try {
    await showAdminLocalAlert(title: title, body: body);
  } catch (e) {
    debugPrint('Admin background local alert failed: $e');
  }
}

Future<void> _subscribeAdminTopic(FirebaseMessaging messaging) async {
  if (_topicSubscribed) return;
  try {
    await messaging.subscribeToTopic(AdminConfig.fcmTopicAdmin);
    _topicSubscribed = true;
    debugPrint('Subscribed to admin FCM topic: ${AdminConfig.fcmTopicAdmin}');
  } catch (e) {
    debugPrint('Admin topic subscribe failed: $e');
  }
}

/// Sets up FCM + local notifications at app launch — before login.
/// This is what makes pushes work when the app is closed.
Future<void> bootstrapAdminNotifications() async {
  if (!DefaultFirebaseOptions.isSupported || _fcmBootstrapped) return;

  try {
    await _ensureAdminFirebase();
    FirebaseMessaging.onBackgroundMessage(adminFirebaseMessagingBackgroundHandler);
    await _pluginWithChannel();

    if (!_isMobilePushPlatform) {
      _fcmBootstrapped = true;
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Admin FCM permission denied at bootstrap');
      _fcmBootstrapped = true;
      return;
    }

    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    await _subscribeAdminTopic(messaging);

    FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ??
          message.data['title'] as String? ??
          'Ujumbe mpya';
      final body = message.notification?.body ??
          message.data['body'] as String? ??
          'New message from user';
      await showAdminLocalAlert(title: title, body: body);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((_) => _globalTapHandler?.call());

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _globalTapHandler?.call();
    }

    _fcmBootstrapped = true;
    debugPrint('Admin FCM bootstrap complete');
  } catch (e) {
    debugPrint('Admin notification bootstrap failed: $e');
  }
}

/// Push + local status-bar alerts for new Maswali messages.
class AdminNotificationService {
  AdminNotificationService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  bool _initialized = false;
  bool _localReady = false;
  String? _authToken;
  String? _lastRegisteredToken;
  int _lastKnownUnread = 0;
  AdminPushTapHandler? onTap;

  Future<void> init({String? authToken}) async {
    _authToken = authToken;
    _globalTapHandler = () => onTap?.call();

    await bootstrapAdminNotifications();

    if (_initialized) {
      if (authToken != null) await refreshRegistration(force: true);
      return;
    }

    await _initLocal();

    if (AdminConfig.hasFirebase && _isMobilePushPlatform) {
      try {
        _messaging = FirebaseMessaging.instance;
        await _subscribeAdminTopic(_messaging!);
        _messaging!.onTokenRefresh.listen((token) {
          registerDevice(token, force: true);
        });
        if (authToken != null) {
          await refreshRegistration(force: true);
        }
      } catch (e) {
        debugPrint('Admin FCM post-login setup failed: $e');
      }
    }

    _initialized = true;
  }

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    if (token != null && _initialized) {
      await refreshRegistration(force: true);
    }
  }

  /// Re-register the device token with the backend (e.g. on login or app resume).
  Future<void> refreshRegistration({bool force = false}) async {
    if (_authToken == null || _authToken!.isEmpty) return;
    if (!_isMobilePushPlatform && !kIsWeb) return;

    try {
      await bootstrapAdminNotifications();
      _messaging ??= FirebaseMessaging.instance;
      final token = await _messaging!.getToken();
      if (token != null) {
        await registerDevice(token, force: force);
      }
    } catch (e) {
      debugPrint('Admin push refresh failed: $e');
    }
  }

  Future<void> registerDevice(String token, {bool force = false}) async {
    if (_authToken == null || _authToken!.isEmpty) return;
    if (!force && _lastRegisteredToken == token) return;

    try {
      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'unknown';
      await _api.post(
        '/api/devices/admin/register',
        body: {'token': token, 'platform': platform},
        token: _authToken,
      );
      _lastRegisteredToken = token;
      debugPrint('Admin FCM token registered with backend');
    } catch (e) {
      debugPrint('Admin token registration failed: $e');
    }
  }

  Future<void> _initLocal() async {
    if (_localReady) return;
    try {
      await _local.initialize(
        settings: _adminInitSettings(),
        onDidReceiveNotificationResponse: (_) => onTap?.call(),
      );
      await _ensureAndroidChannel(_local);
      if (!kIsWeb && Platform.isAndroid) {
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      _localReady = true;
    } catch (e) {
      _localReady = false;
      debugPrint('Admin local notifications unavailable: $e');
    }
  }

  /// Fallback when the app is open — polling detected new unread messages.
  Future<void> onUnreadCountChanged({
    required int unread,
    String? userName,
  }) async {
    if (unread <= 0) {
      _lastKnownUnread = 0;
      return;
    }
    if (unread <= _lastKnownUnread) {
      _lastKnownUnread = unread;
      return;
    }
    _lastKnownUnread = unread;
    final who = (userName != null && userName.trim().isNotEmpty)
        ? userName.trim()
        : 'user';
    await showStatusBarAlert(
      title: 'Ujumbe mpya',
      body: 'New message from $who',
    );
  }

  Future<void> showStatusBarAlert({
    required String title,
    required String body,
  }) async {
    if (!_localReady) {
      await _initLocal();
    }
    if (!_localReady) {
      await showAdminLocalAlert(title: title, body: body);
      return;
    }
    await showAdminLocalAlert(title: title, body: body, plugin: _local);
  }

  void syncBaselineUnread(int unread) {
    _lastKnownUnread = unread;
  }
}
