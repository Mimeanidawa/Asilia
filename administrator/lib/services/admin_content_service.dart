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

  @Deprecated('Use fetchMwalimuSettings')
  Future<Map<String, dynamic>> fetchMtabibuSettings() => fetchMwalimuSettings();

  @Deprecated('Use updateMwalimuSettings')
  Future<void> updateMtabibuSettings(Map<String, dynamic> body) => updateMwalimuSettings(body);

  Future<List<Map<String, dynamic>>> fetchConversations() async {
    final data = await _api.get('/api/chat/admin/conversations', token: _token);
    return List<Map<String, dynamic>>.from(data['conversations'] as List);
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String convId) async {
    final data = await _api.get('/api/chat/admin/conversations/$convId/messages', token: _token);
    return List<Map<String, dynamic>>.from(data['messages'] as List);
  }

  Future<Map<String, dynamic>> replyToConversation(String convId, String content) async {
    return _api.post('/api/chat/admin/conversations/$convId/reply',
        body: {'content': content}, token: _token);
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final data = await _api.get('/api/users/admin/all', token: _token);
    return List<Map<String, dynamic>>.from(data['users'] as List);
  }
}
