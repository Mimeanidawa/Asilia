import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// SharedPreferences persistence for the in-app notification center.
class NotificationStore {
  NotificationStore._();

  static const storageKey = 'da_notifications';
  static const maxItems = 50;

  static Future<List<AppNotification>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> writeAll(List<AppNotification> items) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = items.take(maxItems).toList();
    await prefs.setString(
      storageKey,
      jsonEncode(trimmed.map((n) => n.toJson()).toList()),
    );
  }

  static Future<void> appendFromPush({
    required String title,
    required String body,
    String? lessonId,
    String? contentId,
    String? type,
  }) async {
    final items = await readAll();
    final resolvedType = type ??
        (contentId != null
            ? 'article'
            : lessonId != null
                ? 'lesson'
                : 'general');

    final now = DateTime.now();
    final duplicate = items.any((n) {
      if (contentId != null && n.contentId == contentId) {
        return now.difference(n.timestamp).inMinutes < 2;
      }
      if (lessonId != null && n.lessonId == lessonId) {
        return now.difference(n.timestamp).inMinutes < 2;
      }
      return false;
    });
    if (duplicate) return;

    final updated = [
      AppNotification(
        id: 'push-$resolvedType-${now.millisecondsSinceEpoch}',
        title: title,
        body: body,
        timestamp: now,
        lessonId: lessonId,
        contentId: contentId,
        type: resolvedType,
      ),
      ...items,
    ].take(maxItems).toList();

    await writeAll(updated);
  }
}
