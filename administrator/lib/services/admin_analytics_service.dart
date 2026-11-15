import '../services/api_client.dart';

class AdminAnalyticsService {
  AdminAnalyticsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  String? _token;

  void setToken(String? token) => _token = token;

  Future<Map<String, dynamic>> fetchDashboard() async {
    return _api.get('/api/admin/dashboard', token: _token);
  }

  Future<Map<String, dynamic>> fetchPayments({String? status, int limit = 5000}) async {
    final params = <String, String>{
      'limit': '$limit',
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return _api.get('/api/admin/payments?$query', token: _token);
  }
}
