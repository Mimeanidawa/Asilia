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

const _channelId = 'asilia_admin';
const _channelName = 'Maswali — Admin';

@pragma('vm:entry-point')
Future<void> adminFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AdminConfig.hasFirebase) return;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  debugPrint('Admin background FCM: ${message.notification?.title}');
}

/// Push + local status-bar alerts for new Maswali messages.
/// Notification body never includes the user's message text.
class AdminNotificationService {
  AdminNotificationService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  bool _initialized = false;
  String? _authToken;
  String? _lastToken;
  int _lastKnownUnread = 0;
  AdminPushTapHandler? onTap;

  Future<void> init({String? authToken}) async {
    _authToken = authToken;
    if (_initialized) {
      if (authToken != null) await _registerCurrentToken();
      return;
    }

    await _initLocal();

    if (AdminConfig.hasFirebase &&
        (kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS)))) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _messaging = FirebaseMessaging.instance;
        FirebaseMessaging.onBackgroundMessage(
          adminFirebaseMessagingBackgroundHandler,
        );

        final settings = await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus != AuthorizationStatus.denied) {
          await _messaging!.subscribeToTopic(AdminConfig.fcmTopicAdmin);
          final token = await _messaging!.getToken();
          if (token != null) await registerDevice(token);
          _messaging!.onTokenRefresh.listen(registerDevice);
          FirebaseMessaging.onMessage.listen(_onForeground);
          FirebaseMessaging.onMessageOpenedApp.listen((_) => onTap?.call());
          final initial = await _messaging!.getInitialMessage();
          if (initial != null) onTap?.call();
        }
      } catch (e) {
        debugPrint('Admin FCM init failed (local alerts still work): $e');
      }
    }

    _initialized = true;
  }

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    if (_initialized && token != null) await _registerCurrentToken();
  }

  Future<void> _registerCurrentToken() async {
    final token = await _messaging?.getToken();
    if (token != null) await registerDevice(token);
  }

  Future<void> _initLocal() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (_) => onTap?.call(),
    );

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Arifa za maswali mapya kutoka watumiaji',
        importance: Importance.high,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> registerDevice(String token) async {
    if (_authToken == null || _authToken!.isEmpty) return;
    if (_lastToken == token) return;
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
      _lastToken = token;
    } catch (e) {
      debugPrint('Admin token registration failed: $e');
    }
  }

  Future<void> _onForeground(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title'] as String? ??
        'Ujumbe mpya';
    final body = message.notification?.body ??
        message.data['body'] as String? ??
        'New message from user';
    await showStatusBarAlert(title: title, body: body);
  }

  /// Called when polling detects new unread messages.
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
    // Never allow raw chat content into the status bar.
    final safeBody = body.trim().isEmpty ||
            body.toLowerCase().contains('new message')
        ? body
        : 'New message from user';

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      safeBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Arifa za maswali mapya kutoka watumiaji',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode({'type': 'admin_message'}),
    );
  }

  void syncBaselineUnread(int unread) {
    _lastKnownUnread = unread;
  }
}
