import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/app_config.dart';
import '../firebase_options.dart';
import 'api_client.dart';
import 'notification_store.dart';

typedef NotificationTapHandler = void Function({
  String? lessonId,
  String? contentId,
  String? type,
});

typedef PushNotificationHandler = void Function({
  required String title,
  required String body,
  String? lessonId,
  String? contentId,
  String? type,
});

const _androidChannelId = 'darasa_huru';
const _androidChannelName = 'Dawa Asili Arifa';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AppConfig.hasFirebase) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationStore.appendFromPush(
    title: message.notification?.title ?? message.data['title'] as String? ?? 'Arifa mpya',
    body: message.notification?.body ?? message.data['body'] as String? ?? '',
    lessonId: message.data['lessonId'] as String?,
    contentId: message.data['contentId'] as String?,
    type: message.data['type'] as String?,
  );
  debugPrint('Background FCM stored: ${message.notification?.title}');
}

class NotificationService {
  NotificationService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _lastRegisteredToken;

  NotificationTapHandler? onNotificationTap;
  PushNotificationHandler? onPushReceived;

  bool get isSupported =>
      (kIsWeb && AppConfig.hasFirebase) ||
      (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  Future<void> init() async {
    if (!AppConfig.hasFirebase || !isSupported || _initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _initLocalNotifications();

      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM permission denied');
        return;
      }

      await _messaging!.subscribeToTopic('darasa_huru');
      await _messaging!.subscribeToTopic(AppConfig.fcmTopicAll);

      final token = await _messaging!.getToken();
      if (token != null) {
        await registerDevice(token: token);
      }

      _messaging!.onTokenRefresh.listen((token) => registerDevice(token: token));

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      final initial = await _messaging?.getInitialMessage();
      if (initial != null) _handleMessage(initial);

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _dispatchTap(
            lessonId: _dataString(data, 'lessonId'),
            contentId: _dataString(data, 'contentId'),
            type: _dataString(data, 'type'),
          );
        } catch (_) {}
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: 'Arifa za masomo, makala na ujumbe kutoka Mwalimu',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> registerDevice({
    required String token,
    String? userAuthToken,
  }) async {
    if (!AppConfig.hasApi) return;
    if (_lastRegisteredToken == token && userAuthToken == null) return;

    try {
      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'unknown';
      await _api.post(
        '/api/devices/register',
        body: {
          'token': token,
          'platform': platform,
        },
        token: userAuthToken,
      );
      _lastRegisteredToken = token;
    } catch (e) {
      debugPrint('Token registration failed: $e');
    }
  }

  Future<void> linkToUser(String? userAuthToken) async {
    if (!_initialized || _messaging == null) return;
    final token = await _messaging!.getToken();
    if (token != null) {
      await registerDevice(token: token, userAuthToken: userAuthToken);
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground FCM: ${message.notification?.title}');
    _storePush(message);
    await _showLocalNotification(message);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;
    if (title == null || title.isEmpty) return;

    final dataJson = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      title,
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: 'Arifa za masomo, makala na ujumbe',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: dataJson,
    );
  }

  void _handleMessage(RemoteMessage message) {
    _storePush(message);
    _dispatchTap(
      lessonId: _dataString(message.data, 'lessonId'),
      contentId: _dataString(message.data, 'contentId'),
      type: _dataString(message.data, 'type'),
    );
  }

  String? _dataString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  void _dispatchTap({
    String? lessonId,
    String? contentId,
    String? type,
  }) {
    if (onNotificationTap == null) return;
    onNotificationTap!(
      lessonId: lessonId,
      contentId: contentId,
      type: type,
    );
  }

  void _storePush(RemoteMessage message) {
    if (onPushReceived == null) return;
    final title =
        message.notification?.title ?? message.data['title'] as String? ?? 'Arifa mpya';
    final body =
        message.notification?.body ?? message.data['body'] as String? ?? '';
    final lessonId = _dataString(message.data, 'lessonId');
    final contentId = _dataString(message.data, 'contentId');
    final type = _dataString(message.data, 'type');
    if (title.isEmpty && body.isEmpty) return;
    onPushReceived!(
      title: title,
      body: body,
      lessonId: lessonId,
      contentId: contentId,
      type: type,
    );
  }
}
