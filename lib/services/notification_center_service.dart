import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class NotificationCenterService extends ChangeNotifier {
  List<AppNotification> _items = [];
  bool _loaded = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('da_notifications');
    if (raw != null) {
      _items = (jsonDecode(raw) as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      _items = _defaultNotifications();
      await _persist();
    }
    _loaded = true;
    notifyListeners();
  }

  List<AppNotification> _defaultNotifications() => [];

  Future<void> add(AppNotification notification) async {
    final duplicate = _items.any((n) => n.id == notification.id);
    if (duplicate) return;

    _items = [notification, ..._items].take(50).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> addFromPush({
    required String title,
    required String body,
    String? lessonId,
    String? contentId,
    String? type,
  }) async {
    final resolvedType = type ??
        (contentId != null
            ? 'article'
            : lessonId != null
                ? 'lesson'
                : 'general');

    await add(AppNotification(
      id: 'push-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      lessonId: lessonId,
      contentId: contentId,
      type: resolvedType,
    ));
  }

  Future<void> markRead(String id) async {
    _items = _items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items = [];
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'da_notifications',
      jsonEncode(_items.map((n) => n.toJson()).toList()),
    );
  }
}
