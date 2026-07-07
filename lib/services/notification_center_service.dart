import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import 'notification_store.dart';

class NotificationCenterService extends ChangeNotifier {
  List<AppNotification> _items = [];
  Set<String> _deletedIds = {};
  bool _loaded = false;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _items = await NotificationStore.readAll();
    _deletedIds = await NotificationStore.readDeletedIds();
    _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(AppNotification notification) async {
    if (_items.any((n) => n.id == notification.id)) return;

    _items = [notification, ..._items].take(NotificationStore.maxItems).toList();
    await NotificationStore.writeAll(_items);
    notifyListeners();
  }

  Future<void> addFromPush({
    required String title,
    required String body,
    String? lessonId,
    String? contentId,
    String? type,
    String? imageUrl,
  }) async {
    await NotificationStore.appendFromPush(
      title: title,
      body: body,
      lessonId: lessonId,
      contentId: contentId,
      type: type,
      imageUrl: imageUrl,
    );
    await load();
  }

  /// Adds published posts and lessons that are not already in the center.
  Future<void> syncFromCatalog({
    required List<ContentPost> posts,
    required List<DailyLesson> lessons,
  }) async {
    var changed = false;
    final existingContentIds = _items.map((n) => n.contentId).whereType<String>().toSet();
    final existingLessonIds = _items.map((n) => n.lessonId).whereType<String>().toSet();

    final additions = <AppNotification>[];

    for (final post in posts) {
      if (existingContentIds.contains(post.id)) continue;
      final notificationId = 'content-${post.id}';
      if (_deletedIds.contains(notificationId)) continue;
      additions.add(AppNotification(
        id: notificationId,
        title: 'Makala Mpya — Dawa Asili',
        body: post.title,
        timestamp: DateTime.now(),
        contentId: post.id,
        imageUrl: post.imageUrl,
        type: 'article',
      ));
      existingContentIds.add(post.id);
      changed = true;
    }

    for (final lesson in lessons.where((l) => l.isPublished)) {
      if (existingLessonIds.contains(lesson.id)) continue;
      final notificationId = 'lesson-${lesson.id}';
      if (_deletedIds.contains(notificationId)) continue;
      additions.add(AppNotification(
        id: notificationId,
        title: 'Darasa Huru — Somo Jipya!',
        body: lesson.title,
        timestamp: lesson.publishedAt,
        lessonId: lesson.id,
        imageUrl: lesson.imageUrl,
        type: 'lesson',
      ));
      existingLessonIds.add(lesson.id);
      changed = true;
    }

    if (!changed) return;

    _items = [...additions, ..._items]
        .take(NotificationStore.maxItems)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    await NotificationStore.writeAll(_items);
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    _items = _items.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    await NotificationStore.writeAll(_items);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    await NotificationStore.writeAll(_items);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _deletedIds.add(id);
    _items = _items.where((n) => n.id != id).toList();
    await NotificationStore.addDeletedIds([id]);
    await NotificationStore.writeAll(_items);
    notifyListeners();
  }

  Future<void> clearAll() async {
    if (_items.isEmpty) return;
    final ids = _items.map((n) => n.id).toList();
    _deletedIds.addAll(ids);
    _items = [];
    await NotificationStore.addDeletedIds(ids);
    await NotificationStore.writeAll(_items);
    notifyListeners();
  }
}
