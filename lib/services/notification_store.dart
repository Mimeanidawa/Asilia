import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// SharedPreferences persistence for the in-app notification center.
class NotificationStore {
  NotificationStore._();

  static const storageKey = 'da_notifications';
  static const deletedKey = 'da_notifications_deleted';
  /// v2: install baseline + burst protection (replaces fragile v1 seed-only).
  static const catalogSeededKey = 'da_notifications_catalog_seeded_v2';
  static const installBaselineKey = 'da_notifications_install_baseline_v1';
  static const legacySeededKey = 'da_notifications_catalog_seeded_v1';
  static const maxItems = 50;
  static const maxDeletedIds = 2000;

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
    // Keep newest-ish IDs by dropping from the front of an ordered list.
    final ordered = current.toList();
    final trimmed = ordered.length <= maxDeletedIds
        ? ordered
        : ordered.sublist(ordered.length - maxDeletedIds);
    await prefs.setString(deletedKey, jsonEncode(trimmed));
  }

  static Future<bool> isCatalogSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(catalogSeededKey) ?? false;
  }

  static Future<void> setCatalogSeeded(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(catalogSeededKey, value);
  }

  /// First-open timestamp for this install. Used to ignore historical catalog.
  static Future<DateTime> ensureInstallBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(installBaselineKey);
    if (raw != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    final now = DateTime.now().toUtc();
    await prefs.setString(installBaselineKey, now.toIso8601String());
    return now;
  }

  static Future<DateTime?> readInstallBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(installBaselineKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Clears legacy v1 seed flag after v2 migration.
  static Future<void> clearLegacySeedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacySeededKey);
  }
}
