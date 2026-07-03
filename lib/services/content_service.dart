import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import 'api_client.dart';

class ContentService extends ChangeNotifier {
  ContentService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  List<CarouselSlide> carousels = [];
  List<ContentPost> dodosoPosts = [];
  List<ContentPost> chaguaMadaPosts = [];
  List<ContentPost> vyakulaMatundaPosts = [];
  List<ContentPost> jifunzePosts = [];
  List<RecommendedItem> recommended = [];

  bool isLoading = false;
  String? error;

  Future<void> load({String? userToken}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _loadCache();
      await syncFromServer(userToken: userToken);
    } catch (e) {
      error = e.toString();
      debugPrint('ContentService load error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncFromServer({String? userToken}) async {
    try {
      final carouselData = await _api.get('/api/carousels');
      carousels = (carouselData['carousels'] as List)
          .map((e) => CarouselSlide.fromJson(e as Map<String, dynamic>))
          .toList();

      final dodosoData = await _api.get('/api/content?section=dodoso');
      dodosoPosts = _parsePosts(dodosoData);

      final madaData = await _api.get('/api/content?section=chagua_mada');
      chaguaMadaPosts = _parsePosts(madaData);

      final vyakulaData = await _api.get('/api/content?section=vyakula_matunda');
      vyakulaMatundaPosts = _parsePosts(vyakulaData);
      // Legacy section fallback
      if (vyakulaMatundaPosts.isEmpty) {
        final legacy = await _api.get('/api/content?section=jitibu_nyumbani');
        vyakulaMatundaPosts = _parsePosts(legacy);
      }

      final jifunzeData = await _api.get('/api/content?section=jifunze');
      jifunzePosts = _parsePosts(jifunzeData);

      final recData = await _api.get('/api/content/recommended');
      recommended = (recData['items'] as List)
          .map((e) => RecommendedItem.fromJson(e as Map<String, dynamic>))
          .toList();

      await _saveCache();
      notifyListeners();
    } catch (e) {
      debugPrint('ContentService sync error: $e');
      rethrow;
    }
  }

  Future<ContentPost?> fetchPost(String id, {String? userToken}) async {
    try {
      final data = await _api.get('/api/content/$id', token: userToken);
      return ContentPost.fromJson(data['post'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('fetchPost error: $e');
      return null;
    }
  }

  List<ContentPost> postsForSection(String section, {String? category}) {
    List<ContentPost> posts;
    switch (section) {
      case ContentSections.dodoso:
        posts = dodosoPosts;
        break;
      case ContentSections.chaguaMada:
        posts = chaguaMadaPosts;
        break;
      case ContentSections.vyakulaMatunda:
        posts = vyakulaMatundaPosts;
        break;
      case ContentSections.jifunze:
        posts = jifunzePosts;
        break;
      default:
        posts = [];
    }
    if (category != null) {
      return posts.where((p) => p.category == category).toList();
    }
    return posts;
  }

  List<ContentPost> _parsePosts(Map<String, dynamic> data) =>
      (data['posts'] as List)
          .map((e) => ContentPost.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('da_content_cache_v2');
    if (cached == null) return;

    try {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      carousels = (data['carousels'] as List? ?? [])
          .map((e) => CarouselSlide.fromJson(e as Map<String, dynamic>))
          .toList();
      dodosoPosts = (data['dodoso'] as List? ?? [])
          .map((e) => ContentPost.fromJson(e as Map<String, dynamic>))
          .toList();
      chaguaMadaPosts = (data['chaguaMada'] as List? ?? [])
          .map((e) => ContentPost.fromJson(e as Map<String, dynamic>))
          .toList();
      vyakulaMatundaPosts = (data['vyakulaMatunda'] as List? ?? data['jitibu'] as List? ?? [])
          .map((e) => ContentPost.fromJson(e as Map<String, dynamic>))
          .toList();
      jifunzePosts = (data['jifunze'] as List? ?? [])
          .map((e) => ContentPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('da_content_cache_v2', jsonEncode({
      'carousels': carousels.map((c) => {
            'id': c.id, 'title': c.title, 'subtitle': c.subtitle,
            'imageUrl': c.imageUrl, 'linkSection': c.linkSection,
            'linkId': c.linkId, 'sortOrder': c.sortOrder,
          }).toList(),
      'dodoso': dodosoPosts.map(_postToCache).toList(),
      'chaguaMada': chaguaMadaPosts.map(_postToCache).toList(),
      'vyakulaMatunda': vyakulaMatundaPosts.map(_postToCache).toList(),
      'jifunze': jifunzePosts.map(_postToCache).toList(),
    }));
  }

  Map<String, dynamic> _postToCache(ContentPost p) => {
        'id': p.id, 'section': p.section, 'category': p.category,
        'title': p.title, 'subtitle': p.subtitle, 'excerpt': p.excerpt,
        'imageUrl': p.imageUrl, 'isPremium': p.isPremium, 'price': p.price,
        'readTimeMinutes': p.readTimeMinutes,
      };
}
