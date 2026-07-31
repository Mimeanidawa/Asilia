import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../services/mwalimu_service.dart';
import '../services/lesson_service.dart';
import '../services/notification_center_service.dart';
import '../services/user_service.dart';

/// Centralized silent refresh helpers for pull-to-refresh and background sync.
class AppRefresh {
  AppRefresh._();

  static Future<void> catalog(BuildContext context) async {
    try {
      final content = context.read<ContentService>();
      final user = context.read<UserService>();
      final app = context.read<AppProvider>();
      await Future.wait([
        content.syncFromServer(userToken: user.token),
        app.refreshLessons(silent: true),
      ]);
      // Always baseline/sync notifications AFTER catalog is fresh to avoid
      // seeding from a partial list and inventing the rest as "new".
      if (context.mounted) await notifications(context);
    } catch (_) {}
  }

  static Future<void> user(BuildContext context) async {
    try {
      final user = context.read<UserService>();
      if (user.isLoggedIn) await user.refreshProfile();
    } catch (_) {}
  }

  /// Fresh Premium / unlock-all price from admin settings.
  static Future<void> premiumSettings(BuildContext context) async {
    try {
      await context.read<MwalimuService>().loadSettings();
    } catch (_) {}
  }

  /// After Premium purchase: unlock all makala + unlimited Mwalimu chat.
  static Future<void> afterPremiumPurchase(BuildContext context) async {
    try {
      final user = context.read<UserService>();
      final mwalimu = context.read<MwalimuService>();
      await Future.wait([user.refreshProfile(), mwalimu.loadSettings()]);
      if (user.token != null) {
        await mwalimu.loadMessages(user.token);
      }
    } catch (_) {}
  }

  static Future<void> mwalimu(BuildContext context) async {
    try {
      final mwalimu = context.read<MwalimuService>();
      final user = context.read<UserService>();
      await mwalimu.loadSettings();
      await mwalimu.loadGuestState();
      if (user.token != null) {
        await mwalimu.flushGuestMessagesToServer(user.token!);
        await mwalimu.loadMessages(user.token);
      } else {
        await mwalimu.loadGuestMessages();
      }
    } catch (_) {}
  }

  static Future<void> notifications(BuildContext context) async {
    try {
      final center = context.read<NotificationCenterService>();
      final content = context.read<ContentService>();
      final lessons = context.read<LessonService>();
      if (!center.isLoaded) await center.load();
      await center.syncFromCatalog(
        posts: [
          ...content.dodosoPosts,
          ...content.chaguaMadaPosts,
          ...content.vyakulaMatundaPosts,
          ...content.jifunzePosts,
        ],
        lessons: lessons.publishedLessons,
      );
    } catch (_) {}
  }

  static Future<void> all(BuildContext context) async {
    // Catalog (includes notification sync) first, then user/mwalimu in parallel.
    await catalog(context);
    if (!context.mounted) return;
    await Future.wait([
      user(context),
      mwalimu(context),
    ]);
  }

  static Future<void> contentPost(BuildContext context, String? id) async {
    if (id == null) return;
    try {
      final content = context.read<ContentService>();
      final user = context.read<UserService>();
      await content.fetchPost(id, userToken: user.token);
    } catch (_) {}
  }
}
