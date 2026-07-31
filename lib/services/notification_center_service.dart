import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import 'notification_store.dart';

class NotificationCenterService extends ChangeNotifier {
  List<AppNotification> _items = [];
  Set<String> _deletedIds = {};
  bool _loaded = false;
  Future<void>? _syncInFlight;

  /// More than this many catalog hits in one sync = historical backfill, not "new".
  static const _maxNewPerSync = 3;

  List<AppNotification> get items => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => !n.isRead).length;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    await NotificationStore.ensureInstallBaseline();
    _items = await NotificationStore.readAll();
    _deletedIds = await NotificationStore.readDeletedIds();
    await _migrateLegacyBackfillIfNeeded();
    _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _loaded = true;
    notifyListeners();
  }

  /// One-time: drop catalog-invented history from older buggy installs and
  /// re-baseline so the inbox starts clean going forward.
  Future<void> _migrateLegacyBackfillIfNeeded() async {
    final seededV2 = await NotificationStore.isCatalogSeeded();
    if (seededV2) return;

    final catalogSynthesized = _items
        .where((n) => n.id.startsWith('content-') || n.id.startsWith('lesson-'))
        .toList();
    if (catalogSynthesized.isEmpty) return;

    // Keep real push notifications; discard invented catalog backlog.
    final keep = _items.where((n) => n.id.startsWith('push-')).toList();
    final dropIds = catalogSynthesized.map((n) => n.id).toList();
    _items = keep;
    _deletedIds.addAll(dropIds);
    await NotificationStore.addDeletedIds(dropIds);
    await NotificationStore.writeAll(_items);
    await NotificationStore.clearLegacySeedFlag();
  }

  Future<void> add(AppNotification notification) async {
    if (_items.any((n) => n.id == notification.id)) return;
    if (_deletedIds.contains(notification.id)) return;

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

  /// Syncs newly published catalog items into the notification center.
  ///
  /// First successful sync for this install baselines the current catalog as
  /// already-seen (no history). Later syncs only create a few notifications at
  /// a time; large bursts are treated as catch-up and suppressed.
  Future<void> syncFromCatalog({
    required List<ContentPost> posts,
    required List<DailyLesson> lessons,
  }) {
    final previous = _syncInFlight;
    late final Future<void> current;
    current = () async {
      if (previous != null) await previous;
      await _syncFromCatalogLocked(posts: posts, lessons: lessons);
    }();
    _syncInFlight = current;
    return current;
  }

  Future<void> _syncFromCatalogLocked({
    required List<ContentPost> posts,
    required List<DailyLesson> lessons,
  }) async {
    final baseline = await NotificationStore.ensureInstallBaseline();
    final publishedLessons = lessons.where((l) => l.isPublished).toList();
    if (posts.isEmpty && publishedLessons.isEmpty) return;

    final catalogIds = <String>{
      for (final post in posts) 'content-${post.id}',
      for (final lesson in publishedLessons) 'lesson-${lesson.id}',
    };

    final seeded = await NotificationStore.isCatalogSeeded();
    if (!seeded) {
      await NotificationStore.addDeletedIds(catalogIds);
      _deletedIds = await NotificationStore.readDeletedIds();
      await NotificationStore.setCatalogSeeded(true);
      await NotificationStore.clearLegacySeedFlag();
      // Ensure any leftover invented rows are gone after first baseline.
      final before = _items.length;
      _items = _items.where((n) => n.id.startsWith('push-')).toList();
      if (_items.length != before) {
        await NotificationStore.writeAll(_items);
        notifyListeners();
      }
      return;
    }

    // Refresh deleted-id memory (other isolates / push paths may have updated).
    _deletedIds = await NotificationStore.readDeletedIds();

    final existingContentIds =
        _items.map((n) => n.contentId).whereType<String>().toSet();
    final existingLessonIds =
        _items.map((n) => n.lessonId).whereType<String>().toSet();

    final candidates = <AppNotification>[];

    for (final post in posts) {
      if (existingContentIds.contains(post.id)) continue;
      final notificationId = 'content-${post.id}';
      if (_deletedIds.contains(notificationId)) continue;
      candidates.add(AppNotification(
        id: notificationId,
        title: 'Makala Mpya — Dawa Asili',
        body: post.title,
        timestamp: DateTime.now(),
        contentId: post.id,
        imageUrl: post.imageUrl,
        type: 'article',
      ));
      existingContentIds.add(post.id);
    }

    for (final lesson in publishedLessons) {
      if (existingLessonIds.contains(lesson.id)) continue;
      final notificationId = 'lesson-${lesson.id}';
      if (_deletedIds.contains(notificationId)) continue;
      // Lessons published before this install are historical — never notify.
      if (!lesson.publishedAt.toUtc().isAfter(baseline)) {
        _deletedIds.add(notificationId);
        continue;
      }
      candidates.add(AppNotification(
        id: notificationId,
        title: 'Darasa Huru — Somo Jipya!',
        body: lesson.title,
        timestamp: lesson.publishedAt,
        lessonId: lesson.id,
        imageUrl: lesson.imageUrl,
        type: 'lesson',
      ));
      existingLessonIds.add(lesson.id);
    }

    if (candidates.isEmpty) {
      // Persist any lesson IDs marked historical above.
      final pendingDelete =
          _deletedIds.difference(await NotificationStore.readDeletedIds());
      if (pendingDelete.isNotEmpty) {
        await NotificationStore.addDeletedIds(pendingDelete);
      }
      return;
    }

    // Large burst = catalog catch-up after a partial first seed, not real news.
    if (candidates.length > _maxNewPerSync) {
      await NotificationStore.addDeletedIds(candidates.map((n) => n.id));
      _deletedIds = await NotificationStore.readDeletedIds();
      return;
    }

    _items = [...candidates, ..._items]
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
