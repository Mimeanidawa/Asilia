import 'package:flutter/foundation.dart';

import '../models/daily_lesson.dart';
import 'api_client.dart';

class AdminLessonService extends ChangeNotifier {
  AdminLessonService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  List<DailyLesson> _lessons = [];
  String? _token;
  bool _loading = false;
  String? _lastNotification;

  List<DailyLesson> get lessons {
    final copy = List<DailyLesson>.from(_lessons);
    copy.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return copy;
  }

  bool get isLoading => _loading;
  String? get lastNotification => _lastNotification;

  void setToken(String? token) => _token = token;

  Future<void> load() async {
    if (_token == null) return;
    _loading = true;
    notifyListeners();

    try {
      final data = await _api.get('/api/lessons/admin/all', token: _token);
      _lessons = (data['lessons'] as List)
          .map((e) => _fromApi(e as Map<String, dynamic>))
          .toList();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addLesson(DailyLesson lesson) async {
    final data = await _api.post(
      '/api/lessons/admin',
      token: _token,
      body: _toApiBody(lesson),
    );
    _lessons.insert(0, _fromApi(data['lesson'] as Map<String, dynamic>));
    _captureNotification(data);
    notifyListeners();
  }

  Future<void> updateLesson(DailyLesson lesson) async {
    final data = await _api.put(
      '/api/lessons/admin/${lesson.id}',
      token: _token,
      body: _toApiBody(lesson),
    );
    final updated = _fromApi(data['lesson'] as Map<String, dynamic>);
    final idx = _lessons.indexWhere((l) => l.id == lesson.id);
    if (idx >= 0) _lessons[idx] = updated;
    _captureNotification(data);
    notifyListeners();
  }

  Future<void> deleteLesson(String id) async {
    await _api.delete('/api/lessons/admin/$id', token: _token);
    _lessons.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Future<void> togglePublished(String id) async {
    final data = await _api.patch('/api/lessons/admin/$id/publish', token: _token);
    final updated = _fromApi(data['lesson'] as Map<String, dynamic>);
    final idx = _lessons.indexWhere((l) => l.id == id);
    if (idx >= 0) _lessons[idx] = updated;
    _captureNotification(data);
    notifyListeners();
  }

  void _captureNotification(Map<String, dynamic> data) {
    final n = data['notification'] as Map<String, dynamic>?;
    if (n != null && n['sent'] == true) {
      _lastNotification = 'Push notification sent to all users!';
    } else if (n != null && n['reason'] == 'firebase_not_configured') {
      _lastNotification = 'Lesson saved. Configure Firebase on Railway for push notifications.';
    } else {
      _lastNotification = null;
    }
  }

  Map<String, dynamic> _toApiBody(DailyLesson lesson) => {
        'id': lesson.id,
        'title': lesson.title,
        'excerpt': lesson.excerpt,
        'content': lesson.content,
        'imageUrl': lesson.imageUrl,
        'publishedAt': lesson.publishedAt.toIso8601String().split('T').first,
        'authorName': lesson.authorName,
        'readTimeMinutes': lesson.readTimeMinutes,
        'topicTag': lesson.topicTag,
        'isPublished': lesson.isPublished,
      };

  DailyLesson _fromApi(Map<String, dynamic> json) {
    final publishedAt = json['publishedAt'] as String;
    return DailyLesson(
      id: json['id'] as String,
      title: json['title'] as String,
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      publishedAt: DateTime.parse(
        publishedAt.contains('T') ? publishedAt : '${publishedAt}T00:00:00',
      ),
      authorName: json['authorName'] as String? ?? 'Dr. Mussa Hassan',
      readTimeMinutes: json['readTimeMinutes'] as int? ?? 4,
      topicTag: json['topicTag'] as String?,
      isPublished: json['isPublished'] as bool? ?? false,
    );
  }
}
