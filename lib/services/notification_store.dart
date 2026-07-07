import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// SharedPreferences persistence for the in-app notification center.
class NotificationStore {
  NotificationStore._();

  static const storageKey = 'da_notifications';
  static const deletedKey = 'da_notifications_deleted';
  static const maxItems = 50;
  static const maxDeletedIds = 200;

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
    String? imageUrl,
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
        imageUrl: imageUrl ?? '',
        type: resolvedType,
      ),
      ...items,
    ].take(maxItems).toList();

    await writeAll(updated);
  }

  static Future<Set<String>> readDeletedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(deletedKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> addDeletedIds(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await readDeletedIds();
    current.addAll(ids);
    final trimmed = current.take(maxDeletedIds).toList();
    await prefs.setString(deletedKey, jsonEncode(trimmed));
  }
}
