import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_client.dart';

const _storageKey = 'da_darasa_lessons_v2';
const _lastSyncKey = 'da_darasa_last_sync';

class LessonService extends ChangeNotifier {
  LessonService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  List<DailyLesson> _lessons = [];
  bool _isSyncing = false;
  String? _lastError;

  List<DailyLesson> get lessons => List.unmodifiable(_lessons);
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;

  List<DailyLesson> get publishedLessons {
    final copy = _lessons.where((l) => l.isPublished).toList();
    copy.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return copy;
  }

  Future<void> load() async {
    await _loadFromCache();
    await syncFromServer();
  }

  Future<void> syncFromServer({bool silent = false}) async {
    if (!silent) {
      _isSyncing = true;
      _lastError = null;
      notifyListeners();
    }

    try {
      final data = await _api.get('/api/lessons');
      final list = (data['lessons'] as List)
          .map((e) => _lessonFromApi(e as Map<String, dynamic>))
          .toList();

      // Always replace local state with server truth, including empty lists,
      // so deleted lessons disappear from cached user devices.
      _lessons = list;
      await _persist();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Lesson sync failed: $e');
    } finally {
      if (!silent) _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _lessons = list
          .map((e) => DailyLesson.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_lessons.map((l) => l.toJson()).toList()),
    );
  }

  DailyLesson? get todayLesson {
    final published = publishedLessons;
    if (published.isEmpty) return null;

    final today = published.where((l) => l.isToday).toList();
    if (today.isNotEmpty) return today.first;

    return published.first;
  }

  DailyLesson? lessonById(String id) {
    try {
      return _lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<DailyLesson> lessonsExcept(String id) =>
      publishedLessons.where((l) => l.id != id).toList();

  static DailyLesson _lessonFromApi(Map<String, dynamic> json) {
    final publishedAt = json['publishedAt'];
    DateTime date;
    if (publishedAt is String) {
      date = DateTime.parse(publishedAt.contains('T') ? publishedAt : '${publishedAt}T00:00:00');
    } else {
      date = DateTime.now();
    }

    return DailyLesson(
      id: json['id'] as String,
      title: json['title'] as String,
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      publishedAt: date,
      authorName: json['authorName'] as String? ?? '',
      readTimeMinutes: json['readTimeMinutes'] as int? ?? 4,
      topicTag: json['topicTag'] as String?,
      isPublished: json['isPublished'] as bool? ?? true,
    );
  }
}
