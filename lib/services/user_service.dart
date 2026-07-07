import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import 'api_client.dart';

class UserService extends ChangeNotifier {
  UserService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  AppUser? user;
  String? token;
  List<String> purchasedContentIds = [];
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => token != null && user != null;

  void clearError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('da_user_token');
    final userJson = prefs.getString('da_user_data');
    if (userJson != null) {
      user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    }
    final purchases = prefs.getString('da_purchases');
    if (purchases != null) {
      purchasedContentIds = List<String>.from(jsonDecode(purchases) as List);
    }

    if (token != null) {
      try {
        await refreshProfile();
      } on ApiException catch (e) {
        if (e.statusCode == 403) {
          await logout();
        }
        error = null;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<bool> signup({
    required String fullName,
    String? phone,
    String? email,
    String? password,
    String authProvider = 'phone',
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _api.post('/api/users/signup', body: {
        'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
        'authProvider': authProvider,
      });

      await _saveSession(
        data['token'] as String,
        AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
      return true;
    } catch (e) {
      if (e is ApiException) {
        error = e.message;
      } else {
        error = e.toString().replaceAll('ApiException: ', '');
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({String? email, String? phone, String? password}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _api.post('/api/users/login', body: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (password != null) 'password': password,
      });

      await _saveSession(
        data['token'] as String,
        AppUser.fromJson(data['user'] as Map<String, dynamic>),
      );
      try {
        await refreshProfile();
      } on ApiException catch (e) {
        if (e.statusCode == 403) {
          error = e.message;
          await logout();
          return false;
        }
      }
      return true;
    } catch (e) {
      if (e is ApiException) {
        error = e.message;
      } else {
        error = e.toString().replaceAll('ApiException: ', '');
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (token == null) return;
    try {
      final data = await _api.get('/api/users/me', token: token);
      user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      purchasedContentIds = List<String>.from(data['purchasedContentIds'] as List? ?? []);
      await _persist();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        error = e.message;
        await logout();
      }
      rethrow;
    }
  }

  bool canReadContent(ContentPost post) {
    if (!post.isPremium) return true;
    if (!isLoggedIn) return false;
    if (user!.isPremiumActive) return true;
    return purchasedContentIds.contains(post.id);
  }

  Future<void> logout() async {
    token = null;
    user = null;
    purchasedContentIds = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('da_user_token');
    await prefs.remove('da_user_data');
    await prefs.remove('da_purchases');
    notifyListeners();
  }

  Future<void> _saveSession(String newToken, AppUser newUser) async {
    token = newToken;
    user = newUser;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('da_user_token', token!);
    if (user != null) {
      await prefs.setString('da_user_data', jsonEncode({
        'id': user!.id,
        'fullName': user!.fullName,
        'phone': user!.phone,
        'email': user!.email,
        'authProvider': user!.authProvider,
        'isPremium': user!.isPremium,
        'premiumUntil': user!.premiumUntil?.toIso8601String(),
        'messageCount': user!.messageCount,
      }));
    }
    await prefs.setString('da_purchases', jsonEncode(purchasedContentIds));
  }
}
