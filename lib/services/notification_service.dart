import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../firebase_options.dart';
import 'api_client.dart';

typedef NotificationTapHandler = void Function({
  String? lessonId,
  String? contentId,
});

typedef PushNotificationHandler = void Function({
  required String title,
  required String body,
  String? lessonId,
  String? contentId,
});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!AppConfig.hasFirebase) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM: ${message.notification?.title}');
}

class NotificationService {
  NotificationService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  FirebaseMessaging? _messaging;

  NotificationTapHandler? onNotificationTap;
  PushNotificationHandler? onPushReceived;

  bool get isSupported =>
      (kIsWeb && AppConfig.hasFirebase) ||
      (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

  Future<void> init() async {
    if (!AppConfig.hasFirebase || !isSupported) {
      debugPrint('Firebase notifications skipped (not configured or unsupported platform)');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

      final token = await _messaging!.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      _messaging!.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Foreground FCM: ${message.notification?.title}');
        _storePush(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      final initial = await _messaging?.getInitialMessage();
      if (initial != null) _handleMessage(initial);
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    if (!AppConfig.hasApi) return;
    try {
      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'unknown';
      await _api.post('/api/devices/register', body: {
        'token': token,
        'platform': platform,
      });
    } catch (e) {
      debugPrint('Token registration failed: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    _storePush(message);
    final lessonId = message.data['lessonId'];
    final contentId = message.data['contentId'];
    if (onNotificationTap != null && (lessonId != null || contentId != null)) {
      onNotificationTap!(lessonId: lessonId, contentId: contentId);
    }
  }

  void _storePush(RemoteMessage message) {
    if (onPushReceived == null) return;
    final title = message.notification?.title ?? message.data['title'] ?? 'Arifa mpya';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final lessonId = message.data['lessonId'];
    final contentId = message.data['contentId'];
    if (title.isEmpty && body.isEmpty) return;
    onPushReceived!(
      title: title,
      body: body,
      lessonId: lessonId,
      contentId: contentId,
    );
  }
}
