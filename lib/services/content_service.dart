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

  Future<void> loadFromCache() async {
    final hadCache = await _loadCache();
    if (hadCache) notifyListeners();
  }

  Future<void> load({String? userToken}) async {
    error = null;
    await loadFromCache();

    if (carousels.isEmpty &&
        dodosoPosts.isEmpty &&
        chaguaMadaPosts.isEmpty &&
        vyakulaMatundaPosts.isEmpty &&
        jifunzePosts.isEmpty) {
      isLoading = true;
      notifyListeners();
    }

    try {
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
      // Wake Railway cold start before the heavy catalog call.
      try {
        final health = await _api.get(
          '/api/health',
          timeout: const Duration(seconds: 12),
        );
        final db = health['db']?.toString();
        if (db == 'unreachable' || health['status'] == 'degraded') {
          throw Exception('API database unreachable ($db)');
        }
      } catch (e) {
        // If health itself fails hard, still try catalog once — then stop.
        debugPrint('API health check: $e');
      }

      final catalog = await _api.get('/api/content/catalog');
      _applyCatalog(catalog);
      await _saveCache();
    } catch (catalogError) {
      debugPrint('Catalog sync failed, falling back: $catalogError');
      // Avoid blasting 6 parallel requests when the DB is clearly down —
      // that only multiplies timeouts and stalls the UI.
      final msg = catalogError.toString().toLowerCase();
      final dbDown = msg.contains('timeout') ||
          msg.contains('unreachable') ||
          msg.contains('degraded');
      if (!dbDown) {
        await _syncLegacy();
      } else {
        throw Exception('Server database is unreachable. Using cached content.');
      }
    } finally {
      notifyListeners();
    }
  }

  /// Categories shared across Dodoso, Jifunze, and Vyakula na Matunda.
  static const sharedCategories = {
    'mizizi',
    'miti',
    'matunda',
    'mimea',
    'vyakula',
  };

  void _applyCatalog(Map<String, dynamic> data) {
    carousels = (data['carousels'] as List? ?? [])
        .map((e) => CarouselSlide.fromJson(e as Map<String, dynamic>))
        .toList();

    final posts = data['posts'] as Map<String, dynamic>? ?? {};
    dodosoPosts = _parsePostsMap(posts['dodoso']);
    chaguaMadaPosts = _parsePostsMap(posts['chagua_mada']);
    vyakulaMatundaPosts = _mergeVyakulaPosts(
      _parsePostsMap(posts['vyakula_matunda']),
      _parsePostsMap(posts['jitibu_nyumbani']),
    );
    jifunzePosts = _parsePostsMap(posts['jifunze']);
    recommended = (data['recommended'] as List? ?? [])
        .map((e) => RecommendedItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<ContentPost> _parsePostsMap(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => ContentPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _syncLegacy() async {
    // Resilient: apply whatever succeeds instead of failing the whole sync.
    final carouselsF = _safeGet('/api/carousels');
    final dodosoF = _safeGet('/api/content?section=dodoso');
    final chaguaF = _safeGet('/api/content?section=chagua_mada');
    final vyakulaF = _safeGet('/api/content?section=vyakula_matunda');
    final jifunzeF = _safeGet('/api/content?section=jifunze');
    final recommendedF = _safeGet('/api/content/recommended');

    final results = await Future.wait([
      carouselsF,
      dodosoF,
      chaguaF,
      vyakulaF,
      jifunzeF,
      recommendedF,
    ]);

    var any = false;
    if (results[0] != null) {
      carousels = (results[0]!['carousels'] as List)
          .map((e) => CarouselSlide.fromJson(e as Map<String, dynamic>))
          .toList();
      any = true;
    }
    if (results[1] != null) {
      dodosoPosts = _parsePosts(results[1]!);
      any = true;
    }
    if (results[2] != null) {
      chaguaMadaPosts = _parsePosts(results[2]!);
      any = true;
    }
    if (results[3] != null) {
      var vyakula = _parsePosts(results[3]!);
      final legacy = await _safeGet('/api/content?section=jitibu_nyumbani');
      if (legacy != null) {
        vyakula = _mergeVyakulaPosts(vyakula, _parsePosts(legacy));
      }
      vyakulaMatundaPosts = vyakula;
      any = true;
    }
    if (results[4] != null) {
      jifunzePosts = _parsePosts(results[4]!);
      any = true;
    }
    if (results[5] != null) {
      recommended = (results[5]!['items'] as List)
          .map((e) => RecommendedItem.fromJson(e as Map<String, dynamic>))
          .toList();
      any = true;
    }

    if (any) {
      await _saveCache();
    } else {
      throw Exception('Content sync failed for all endpoints');
    }
  }

  Future<Map<String, dynamic>?> _safeGet(String path) async {
    try {
      return await _api.get(path);
    } catch (e) {
      debugPrint('Content GET $path failed: $e');
      return null;
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

  List<ContentPost> _mergeVyakulaPosts(
    List<ContentPost> primary,
    List<ContentPost> legacy,
  ) {
    final seen = <String>{};
    final merged = <ContentPost>[];
    for (final post in [...primary, ...legacy]) {
      if (seen.add(post.id)) merged.add(post);
    }
    return merged;
  }

  List<ContentPost> _postsForSectionOnly(String section) {
    switch (section) {
      case ContentSections.dodoso:
        return dodosoPosts;
      case ContentSections.chaguaMada:
        return chaguaMadaPosts;
      case ContentSections.vyakulaMatunda:
        return vyakulaMatundaPosts;
      case ContentSections.jifunze:
        return jifunzePosts;
      default:
        return [];
    }
  }

  List<ContentPost> _filterByCategory(List<ContentPost> posts, String category) {
    final key = category.trim().toLowerCase();
    return posts
        .where((p) => (p.category ?? '').trim().toLowerCase() == key)
        .toList();
  }

  /// All posts matching [category] across every section (e.g. all Mizizi posts).
  List<ContentPost> postsForCategory(String category) {
    final key = category.trim().toLowerCase();
    if (key.isEmpty) return allMakalaPosts;
    return _filterByCategory(allPosts, key);
  }

  int countForCategory(String category) => postsForCategory(category).length;

  List<ContentPost> postsForSection(String section, {String? category}) {
    if (section == ContentSections.allMakala) {
      final posts = allMakalaPosts;
      if (category != null && category.isNotEmpty) {
        return _filterByCategory(posts, category);
      }
      return posts;
    }

    if (category != null && category.isNotEmpty) {
      final key = category.trim().toLowerCase();
      // Shared categories appear in Dodoso, Jifunze, Vyakula — show all matching posts.
      if (sharedCategories.contains(key)) {
        return postsForCategory(key);
      }
      return _filterByCategory(_postsForSectionOnly(section), key);
    }
    return _postsForSectionOnly(section);
  }

  /// Every content post in the app (all sections, deduplicated).
  List<ContentPost> get allPosts {
    final seen = <String>{};
    final combined = <ContentPost>[];
    for (final post in [
      ...dodosoPosts,
      ...chaguaMadaPosts,
      ...vyakulaMatundaPosts,
      ...jifunzePosts,
    ]) {
      if (seen.add(post.id)) combined.add(post);
    }
    return combined;
  }

  /// All published-style posts across Dodoso, Chagua Mada, Vyakula na Matunda, and Jifunze.
  List<ContentPost> get allMakalaPosts {
    final seen = <String>{};
    final combined = <ContentPost>[];
    for (final post in [
      ...dodosoPosts.where((p) => p.category != 'darasa_huru'),
      ...chaguaMadaPosts,
      ...vyakulaMatundaPosts,
      ...jifunzePosts,
    ]) {
      if (seen.add(post.id)) combined.add(post);
    }
    return combined;
  }

  List<ContentPost> _parsePosts(Map<String, dynamic> data) =>
      (data['posts'] as List)
          .map((e) => ContentPost.fromJson(e as Map<String, dynamic>))
          .toList();

  Future<bool> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('da_content_cache_v3');
    if (cached == null) return false;

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
      return carousels.isNotEmpty ||
          dodosoPosts.isNotEmpty ||
          chaguaMadaPosts.isNotEmpty ||
          vyakulaMatundaPosts.isNotEmpty ||
          jifunzePosts.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('da_content_cache_v3', jsonEncode({
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
