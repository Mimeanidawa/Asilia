import '../services/api_client.dart';

class AdminContentService {
  AdminContentService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  String? _token;

  void setToken(String? token) => _token = token;

  Future<List<Map<String, dynamic>>> fetchCarousels() async {
    final data = await _api.get('/api/carousels/admin/all', token: _token);
    return List<Map<String, dynamic>>.from(data['carousels'] as List);
  }

  Future<Map<String, dynamic>> createCarousel(Map<String, dynamic> body) async {
    return _api.post('/api/carousels/admin', body: body, token: _token);
  }

  Future<Map<String, dynamic>> updateCarousel(String id, Map<String, dynamic> body) async {
    return _api.put('/api/carousels/admin/$id', body: body, token: _token);
  }

  Future<void> deleteCarousel(String id) async {
    await _api.delete('/api/carousels/admin/$id', token: _token);
  }

  Future<List<Map<String, dynamic>>> fetchPosts({String? section, String? category}) async {
    var path = '/api/content/admin/all';
    final params = <String>[];
    if (section != null) params.add('section=$section');
    if (category != null) params.add('category=$category');
    if (params.isNotEmpty) path += '?${params.join('&')}';

    final data = await _api.get(path, token: _token);
    return List<Map<String, dynamic>>.from(data['posts'] as List);
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> body) async {
    return _api.post('/api/content/admin', body: body, token: _token);
  }

  Future<Map<String, dynamic>> updatePost(String id, Map<String, dynamic> body) async {
    return _api.put('/api/content/admin/$id', body: body, token: _token);
  }

  Future<Map<String, dynamic>> togglePublishPost(String id) async {
    return _api.patch('/api/content/admin/$id/publish', token: _token);
  }

  Future<void> deletePost(String id) async {
    await _api.delete('/api/content/admin/$id', token: _token);
  }

  Future<Map<String, dynamic>> fetchMwalimuSettings() async {
    return _api.get('/api/chat/settings');
  }

  Future<void> updateMwalimuSettings(Map<String, dynamic> body) async {
    await _api.put('/api/chat/settings', body: body, token: _token);
  }

  Future<Map<String, dynamic>> fetchAppConfig() async {
    return _api.get('/api/app/config');
  }

  Future<Map<String, dynamic>> updateAppConfig(Map<String, dynamic> body) async {
    return _api.put('/api/app/config', body: body, token: _token);
  }

  @Deprecated('Use fetchMwalimuSettings')
  Future<Map<String, dynamic>> fetchMtabibuSettings() => fetchMwalimuSettings();

  @Deprecated('Use updateMwalimuSettings')
  Future<void> updateMtabibuSettings(Map<String, dynamic> body) => updateMwalimuSettings(body);

  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final data = await _api.get('/api/chat/admin/conversations', token: _token);
    return List<Map<String, dynamic>>.from(data['conversations'] as List);
  }

  Future<Map<String, dynamic>> fetchUnreadSummary() async {
    return _api.get('/api/chat/admin/unread-summary', token: _token);
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String convId) async {
    final data = await _api.get('/api/chat/admin/conversations/$convId/messages', token: _token);
    return List<Map<String, dynamic>>.from(data['messages'] as List);
  }

  Future<void> markConversationRead(String convId) async {
    await _api.post('/api/chat/admin/conversations/$convId/read', token: _token);
  }

  Future<Map<String, dynamic>> replyToConversation(String convId, String content) async {
    return _api.post('/api/chat/admin/conversations/$convId/reply',
        body: {'content': content}, token: _token);
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final data = await _api.get('/api/users/admin/all', token: _token);
    return List<Map<String, dynamic>>.from(data['users'] as List);
  }

  Future<Map<String, dynamic>> updateUserPremium(String userId, bool isPremium) async {
    return _api.patch('/api/users/admin/$userId/premium',
        body: {'isPremium': isPremium}, token: _token);
  }

  Future<Map<String, dynamic>> updateUserStatus(String userId, String status) async {
    return _api.patch('/api/users/admin/$userId/status',
        body: {'status': status}, token: _token);
  }

  Future<Map<String, dynamic>> sendBroadcast({
    required String title,
    required String body,
    required String target,
    String? contentId,
    String? imageUrl,
  }) async {
    return _api.post(
      '/api/devices/broadcast',
      body: {
        'title': title,
        'body': body,
        'target': target,
        if (contentId != null && contentId.isNotEmpty) 'contentId': contentId,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      },
      token: _token,
    );
  }

  Future<Map<String, dynamic>> sharePost(
    String id, {
    String? title,
    String? body,
  }) async {
    return _api.post(
      '/api/content/admin/$id/share',
      body: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (body != null && body.isNotEmpty) 'body': body,
      },
      token: _token,
    );
  }

  Future<List<Map<String, dynamic>>> fetchNotificationHistory() async {
    final data = await _api.get('/api/notifications/admin', token: _token);
    final list = data['notifications'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete('/api/notifications/admin/$id', token: _token);
  }

  Future<void> clearNotificationHistory() async {
    await _api.delete('/api/notifications/admin', token: _token);
  }
}
