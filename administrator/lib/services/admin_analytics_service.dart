import '../services/api_client.dart';

class AdminAnalyticsService {
  AdminAnalyticsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  String? _token;

  void setToken(String? token) => _token = token;

  Future<Map<String, dynamic>> fetchDashboard() async {
    return _api.get('/api/admin/dashboard', token: _token);
  }
}
