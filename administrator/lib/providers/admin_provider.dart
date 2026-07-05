import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../models/admin_models.dart';
import '../models/daily_lesson.dart';
import '../services/admin_analytics_service.dart';
import '../services/admin_lesson_service.dart';
import '../services/admin_content_service.dart';
import '../services/api_client.dart';
import '../utils/admin_data_mapper.dart';

enum AdminScreen { dashboard, users, analytics, notifications, content, darasaHuru, mwalimu, settings }

class AdminProvider extends ChangeNotifier {
  AdminProvider({
    AdminLessonService? lessonService,
    AdminContentService? contentService,
    AdminAnalyticsService? analyticsService,
    ApiClient? apiClient,
  })  : _lessonService = lessonService ?? AdminLessonService(),
        _contentService = contentService ?? AdminContentService(),
        _analyticsService = analyticsService ?? AdminAnalyticsService(),
        _api = apiClient ?? ApiClient() {
    _init();
    _restoreSession();
  }

  final AdminLessonService _lessonService;
  final AdminContentService _contentService;
  final AdminAnalyticsService _analyticsService;
  final ApiClient _api;

  AdminScreen _activeScreen = AdminScreen.dashboard;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _authToken;
  String? _adminName;
  String? _adminEmail;
  String? _loginError;

  late DashboardStats _stats;
  late List<AdminUser> _users;
  late List<AdminNotification> _notifications;
  late List<ContentItem> _contentItems;
  late List<MonthlyMetric> _userGrowth;
  late List<MonthlyMetric> _revenueData;
  late List<MonthlyMetric> _premiumGrowth;
  late List<RecentActivity> _recentActivities;

  String _userSearchQuery = '';
  UserPlan? _userPlanFilter;
  UserStatus? _userStatusFilter;
  String _contentTabFilter = 'All';

  AdminScreen get activeScreen => _activeScreen;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get loginError => _loginError;
  String? get adminEmail => _adminEmail;
  String? get lastPushNotification => _lessonService.lastNotification;
  DashboardStats get stats => _stats;
  List<MonthlyMetric> get userGrowth => _userGrowth;
  List<MonthlyMetric> get revenueData => _revenueData;
  List<MonthlyMetric> get premiumGrowth => _premiumGrowth;
  List<RecentActivity> get recentActivities => _recentActivities;
  List<AdminNotification> get notifications => _notifications;
  List<ContentItem> get contentItems => _contentItems;
  List<DailyLesson> get lessons => _lessonService.lessons;
  bool get lessonsLoading => _lessonService.isLoading;
  AdminContentService get contentService => _contentService;
  List<AdminUser> get users => _users;
  String get contentTabFilter => _contentTabFilter;
  UserPlan? get userPlanFilter => _userPlanFilter;
  UserStatus? get userStatusFilter => _userStatusFilter;

  List<AdminUser> get filteredUsers {
    return _users.where((u) {
      final q = _userSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          (u.email?.toLowerCase().contains(q) ?? false) ||
          (u.phone?.contains(q) ?? false);
      final matchesPlan = _userPlanFilter == null || u.plan == _userPlanFilter;
      final matchesStatus = _userStatusFilter == null || u.status == _userStatusFilter;
      return matchesSearch && matchesPlan && matchesStatus;
    }).toList();
  }

  List<ContentItem> get filteredContent {
    if (_contentTabFilter == 'All') return _contentItems;
    if (_contentTabFilter == 'Herbs') return _contentItems.where((c) => c.type == ContentType.herb).toList();
    if (_contentTabFilter == 'Conditions') return _contentItems.where((c) => c.type == ContentType.condition).toList();
    if (_contentTabFilter == 'Articles') return _contentItems.where((c) => c.type == ContentType.article).toList();
    return _contentItems;
  }

  void _init() {
    _stats = MockData.stats;
    _users = List.from(MockData.users);
    _notifications = List.from(MockData.notifications);
    _contentItems = List.from(MockData.contentItems);
    _userGrowth = MockData.userGrowth;
    _revenueData = MockData.revenueData;
    _premiumGrowth = MockData.premiumGrowth;
    _recentActivities = MockData.recentActivities;
  }

  void _setAuthTokens(String? token) {
    _authToken = token;
    _lessonService.setToken(token);
    _contentService.setToken(token);
    _analyticsService.setToken(token);
  }

  Future<void> _loadDashboardData() async {
    if (_authToken == null) return;

    final dashboard = await _analyticsService.fetchDashboard();
    _stats = AdminDataMapper.statsFromJson(dashboard['stats'] as Map<String, dynamic>);
    _userGrowth = AdminDataMapper.metricsFromJson(dashboard['userGrowth'] as List);
    _revenueData = AdminDataMapper.metricsFromJson(dashboard['revenueData'] as List);
    _premiumGrowth = AdminDataMapper.metricsFromJson(dashboard['premiumGrowth'] as List);
    _recentActivities = AdminDataMapper.activitiesFromJson(dashboard['recentActivities'] as List);

    final rawUsers = await _contentService.fetchUsers();
    _users = rawUsers.map(AdminDataMapper.userFromJson).toList();
  }

  Future<void> refreshData() async {
    if (!_isLoggedIn || _authToken == null) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      await _loadDashboardData();
    } catch (_) {
      // Keep existing data on refresh failure.
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('admin_auth_token');
    if (token != null) {
      _setAuthTokens(token);
      try {
        final data = await _api.get('/api/auth/me', token: token);
        final admin = data['admin'] as Map<String, dynamic>;
        _adminName = admin['name'] as String?;
        _adminEmail = admin['email'] as String?;
        _isLoggedIn = true;
        await Future.wait([_lessonService.load(), _loadDashboardData()]);
      } catch (_) {
        await prefs.remove('admin_auth_token');
        _setAuthTokens(null);
        _isLoggedIn = false;
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _loginError = null;
    notifyListeners();

    try {
      final data = await _api.post('/api/auth/login', body: {
        'email': email.trim(),
        'password': password,
      });

      _setAuthTokens(data['token'] as String);
      final admin = data['admin'] as Map<String, dynamic>;
      _adminName = admin['name'] as String?;
      _adminEmail = admin['email'] as String?;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_auth_token', _authToken!);

      await Future.wait([_lessonService.load(), _loadDashboardData()]);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loginError = e.toString().replaceAll('ApiException: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _authToken = null;
    _adminName = null;
    _adminEmail = null;
    _activeScreen = AdminScreen.dashboard;
    _setAuthTokens(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_auth_token');
    notifyListeners();
  }

  void setScreen(AdminScreen screen) {
    _activeScreen = screen;
    if (!_isLoggedIn) {
      notifyListeners();
      return;
    }
    switch (screen) {
      case AdminScreen.darasaHuru:
        refreshLessons();
      case AdminScreen.dashboard:
      case AdminScreen.users:
      case AdminScreen.analytics:
      case AdminScreen.notifications:
      case AdminScreen.settings:
        refreshData();
      case AdminScreen.content:
      case AdminScreen.mwalimu:
        break;
    }
    notifyListeners();
  }

  void setUserSearch(String query) {
    _userSearchQuery = query;
    notifyListeners();
  }

  void setUserPlanFilter(UserPlan? plan) {
    _userPlanFilter = plan;
    notifyListeners();
  }

  void setUserStatusFilter(UserStatus? status) {
    _userStatusFilter = status;
    notifyListeners();
  }

  void clearUserFilters() {
    _userSearchQuery = '';
    _userPlanFilter = null;
    _userStatusFilter = null;
    notifyListeners();
  }

  Future<String?> updateUserStatus(String userId, UserStatus status) async {
    try {
      final data = await _contentService.updateUserStatus(userId, status.name);
      final userJson = data['user'];
      if (userJson is! Map<String, dynamic>) {
        return 'Jibu la seva si sahihi';
      }
      final updated = AdminDataMapper.userFromJson(userJson);
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        _users[idx] = updated;
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updateUserPlan(String userId, UserPlan plan) async {
    try {
      final data = await _contentService.updateUserPremium(userId, plan == UserPlan.premium);
      final userJson = data['user'];
      if (userJson is! Map<String, dynamic>) {
        return 'Jibu la seva si sahihi';
      }
      final updated = AdminDataMapper.userFromJson(userJson);
      final idx = _users.indexWhere((u) => u.id == userId);
      if (idx != -1) {
        _users[idx] = updated;
        await _loadDashboardData();
        notifyListeners();
      }
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  void addNotification(AdminNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void setContentTabFilter(String filter) {
    _contentTabFilter = filter;
    notifyListeners();
  }

  void toggleContentPublished(String contentId) {
    final idx = _contentItems.indexWhere((c) => c.id == contentId);
    if (idx != -1) {
      _contentItems[idx].isPublished = !_contentItems[idx].isPublished;
      notifyListeners();
    }
  }

  void addContentItem(ContentItem item) {
    _contentItems.insert(0, item);
    notifyListeners();
  }

  void deleteContent(String contentId) {
    _contentItems.removeWhere((c) => c.id == contentId);
    notifyListeners();
  }

  Future<void> refreshLessons() => _lessonService.load();

  Future<void> addLesson(DailyLesson lesson) async {
    await _lessonService.addLesson(lesson);
    notifyListeners();
  }

  Future<void> updateLesson(DailyLesson lesson) async {
    await _lessonService.updateLesson(lesson);
    notifyListeners();
  }

  Future<void> deleteLesson(String id) async {
    await _lessonService.deleteLesson(id);
    notifyListeners();
  }

  Future<void> toggleLessonPublished(String id) async {
    await _lessonService.togglePublished(id);
    notifyListeners();
  }
}
