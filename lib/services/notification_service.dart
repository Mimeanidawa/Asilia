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
  String? imageUrl,
});

const androidChannelId = 'darasa_huru';
const androidChannelName = 'Dawa Asili Taarifa';

class _PendingTap {
  const _PendingTap({this.lessonId, this.contentId, this.type});
  final String? lessonId;
  final String? contentId;
  final String? type;
}

String? fcmDataString(Map<String, dynamic> data, String key) {
  final value = data[key] ?? data[key.toLowerCase()];
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String? fcmImageUrl(RemoteMessage message) {
  return message.notification?.android?.imageUrl ??
      message.notification?.apple?.imageUrl ??
      fcmDataString(message.data, 'imageUrl');
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AppConfig.hasFirebase) return;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (_) {}
  await NotificationStore.appendFromPush(
    title: message.notification?.title ??
        fcmDataString(message.data, 'title') ??
        'Taarifa mpya',
    body: message.notification?.body ?? fcmDataString(message.data, 'body') ?? '',
    lessonId: fcmDataString(message.data, 'lessonId'),
    contentId: fcmDataString(message.data, 'contentId'),
    type: fcmDataString(message.data, 'type'),
    imageUrl: fcmImageUrl(message),
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
  _PendingTap? _pendingTap;

  NotificationTapHandler? _onNotificationTap;
  PushNotificationHandler? onPushReceived;

  NotificationTapHandler? get onNotificationTap => _onNotificationTap;

  set onNotificationTap(NotificationTapHandler? handler) {
    _onNotificationTap = handler;
    final pending = _pendingTap;
    if (handler != null && pending != null) {
      _pendingTap = null;
      handler(
        lessonId: pending.lessonId,
        contentId: pending.contentId,
        type: pending.type,
      );
    }
  }

  bool get isSupported =>
      (kIsWeb && AppConfig.hasFirebase) ||
      (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  Future<void> init() async {
    if (!DefaultFirebaseOptions.isSupported || !isSupported || _initialized) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _messaging = FirebaseMessaging.instance;

      await _initLocalNotifications();

      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM permission denied');
        return;
      }

      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );

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
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _dispatchTap(
            lessonId: fcmDataString(data, 'lessonId'),
            contentId: fcmDataString(data, 'contentId'),
            type: fcmDataString(data, 'type'),
          );
        } catch (_) {}
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        androidChannelId,
        androidChannelName,
        description: 'Taarifa za masomo, makala na ujumbe kutoka Mwalimu',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(channel);
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
    final title = notification?.title ?? fcmDataString(message.data, 'title');
    final body = notification?.body ?? fcmDataString(message.data, 'body');
    if (title == null || title.isEmpty) return;

    final dataJson = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      title,
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: 'Taarifa za masomo, makala na ujumbe',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
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
      lessonId: fcmDataString(message.data, 'lessonId'),
      contentId: fcmDataString(message.data, 'contentId'),
      type: fcmDataString(message.data, 'type'),
    );
  }

  void _dispatchTap({
    String? lessonId,
    String? contentId,
    String? type,
  }) {
    final handler = _onNotificationTap;
    if (handler == null) {
      _pendingTap = _PendingTap(
        lessonId: lessonId,
        contentId: contentId,
        type: type,
      );
      return;
    }
    handler(
      lessonId: lessonId,
      contentId: contentId,
      type: type,
    );
  }

  void _storePush(RemoteMessage message) {
    if (onPushReceived == null) return;
    final title = message.notification?.title ??
        fcmDataString(message.data, 'title') ??
        'Taarifa mpya';
    final body =
        message.notification?.body ?? fcmDataString(message.data, 'body') ?? '';
    final lessonId = fcmDataString(message.data, 'lessonId');
    final contentId = fcmDataString(message.data, 'contentId');
    final type = fcmDataString(message.data, 'type');
    final imageUrl = fcmImageUrl(message);
    if (title.isEmpty && body.isEmpty) return;
    onPushReceived!(
      title: title,
      body: body,
      lessonId: lessonId,
      contentId: contentId,
      type: type,
      imageUrl: imageUrl,
    );
  }
}
