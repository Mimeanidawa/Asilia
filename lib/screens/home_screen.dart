import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../services/notification_center_service.dart';
import '../theme/app_colors.dart';
import '../widgets/api_carousel.dart';
import '../widgets/carousel_content_picker_sheet.dart';
import '../widgets/app_drawer.dart';
import '../widgets/content_post_card.dart';
import '../widgets/darasa_huru_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/learning_pathways_row.dart';
import '../utils/app_refresh.dart';
import '../utils/premium_content_flow.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  List<String> _recentSearches = [];
  bool _isInputFocused = false;
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchFocus.addListener(() {
      setState(() => _isInputFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('da_recent_searches');
    if (saved != null) {
      setState(() {
        _recentSearches = List<String>.from(jsonDecode(saved) as List);
      });
    }
  }

  Future<void> _commitSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final filtered =
        _recentSearches.where((s) => s.toLowerCase() != trimmed.toLowerCase());
    final updated = [trimmed, ...filtered].take(3).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('da_recent_searches', jsonEncode(updated));
    setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('da_recent_searches');
    setState(() => _recentSearches = []);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final content = context.watch<ContentService>();
    final q = _searchQuery.toLowerCase().trim();

    final filteredPosts = q.isEmpty ? <ContentPost>[] : _searchPosts(content, q);
    final filteredLessons = q.isEmpty
        ? <DailyLesson>[]
        : app.lessonService.publishedLessons.where((lesson) {
            return lesson.title.toLowerCase().contains(q) ||
                lesson.excerpt.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.cream,
      body: SizedBox.expand(
      child: Column(
      children: [
        _buildHeader(context, app),
        Expanded(
          child: PullToRefresh(
            onRefresh: () => AppRefresh.catalog(context),
            child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _buildGreetingAndSearch(context),
              if (_searchQuery.isNotEmpty)
                _buildSearchResults(
                  context,
                  app,
                  filteredPosts,
                  filteredLessons,
                )
              else ...[
                _buildHeroCarousel(context),
                const StatsStrip(),
                _buildLearningPathways(context, app),
                _buildDarasaHuru(context, app),
                _buildCategoryGrid(context, app),
                _buildMakalaSection(context, app),
              ],
            ],
          ),
          ),
        ),
      ],
    ),
    ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider app) {
    final unread = context.watch<NotificationCenterService>().unreadCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.03)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.forest, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Row(
            children: [
              const Icon(Icons.eco, color: AppColors.emerald700, size: 18),
              const SizedBox(width: 6),
              Text(
                'Dawa Asili',
                style: TextStyle(
                  fontFamily: kIsWeb ? null : 'Playfair Display',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.forest),
                onPressed: () => app.navigate(AppScreen.notifications),
              ),
              if (unread > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingAndSearch(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.cream],
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Karibu!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jifunze dawa asilia za vyakula, matunda na mimea hapa',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.forest.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(Icons.spa, color: AppColors.forest, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: _commitSearch,
                decoration: InputDecoration(
                  hintText: 'Tafuta mimea, mizizi, miti, matunda...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppColors.forest.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.forest.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              if (_isInputFocused && _recentSearches.isNotEmpty)
                Positioned(
                  top: 52,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.forest.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RECENT SEARCHES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray400,
                                  letterSpacing: 1,
                                ),
                              ),
                              GestureDetector(
                                onTap: _clearRecentSearches,
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.red600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._recentSearches.map(
                            (term) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                term,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppColors.forest.withValues(alpha: 0.3),
                              ),
                              onTap: () {
                                _searchController.text = term;
                                setState(() {
                                  _searchQuery = term;
                                  _isInputFocused = false;
                                });
                                _searchFocus.unfocus();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<ContentPost> _searchPosts(ContentService content, String q) {
    final all = [
      ...content.dodosoPosts,
      ...content.chaguaMadaPosts,
      ...content.vyakulaMatundaPosts,
      ...content.jifunzePosts,
    ];
    return all
        .where((p) =>
            p.title.toLowerCase().contains(q) ||
            p.excerpt.toLowerCase().contains(q) ||
            (p.subtitle.toLowerCase().contains(q)))
        .toList();
  }

  Widget _buildSearchResults(
    BuildContext context,
    AppProvider app,
    List<ContentPost> posts,
    List<DailyLesson> lessons,
  ) {
    final total = posts.length + lessons.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MATOKEO YA UTAFUTAJI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray400,
                  letterSpacing: 1,
                ),
              ),
              if (total > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total yamepatikana',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.emerald800,
                    ),
                  ),
                ),
            ],
          ),
          if (lessons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Masomo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.emerald800,
              ),
            ),
            const SizedBox(height: 8),
            ...lessons.map(
              (lesson) => _LessonSearchTile(
                lesson: lesson,
                onTap: () {
                  _commitSearch(_searchQuery);
                  app.navigate(AppScreen.darasaHuru, lessonId: lesson.id);
                },
              ),
            ),
          ],
          if (posts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Makala',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.emerald800,
              ),
            ),
            const SizedBox(height: 8),
            ...posts.map(
              (post) => _ContentSearchTile(
                post: post,
                onTap: () {
                  _commitSearch(_searchQuery);
                  openContentPost(context, post);
                },
              ),
            ),
          ],
          if (posts.isEmpty && lessons.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Hakuna maudhui ya "$_searchQuery".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gray400, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jaribu neno lingine au angalia tena baadaye.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gray400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel(BuildContext context) {
    final content = context.watch<ContentService>();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ApiCarousel(
        slides: content.carousels,
        height: 210,
        autoPlay: true,
        onSlideTap: (slide) => _handleCarouselTap(context, slide),
      ),
    );
  }

  void _handleCarouselTap(BuildContext context, CarouselSlide slide) {
    showCarouselContentPicker(context, slide: slide);
  }

  Widget _buildLearningPathways(BuildContext context, AppProvider app) {
    final dodosoCats = [
      ('darasa_huru', 'Darasa Huru', 'Somo la kila siku', Icons.school_rounded, const [Color(0xFF0C2E1F), Color(0xFF1C4731)]),
      ('mizizi', 'Mizizi', 'Mizizi ya dawa asili', Icons.grass_rounded, const [Color(0xFF065F46), Color(0xFF047857)]),
      ('miti', 'Miti', 'Miti na faida zake', Icons.park_rounded, const [Color(0xFF1C4731), Color(0xFF113121)]),
      ('matunda', 'Matunda', 'Matunda ya asili', Icons.apple_rounded, const [Color(0xFFB45309), Color(0xFF836C45)]),
      ('mimea', 'Mimea', 'Mimea mbalimbali', Icons.eco_rounded, const [Color(0xFF1E40AF), Color(0xFF1E3A8A)]),
    ];

    return Column(
      children: [
        const SectionHeader(
          title: 'Dodoso',
          subtitle: 'Jifunze kuhusu mizizi, miti na matunda',
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
        ),
        LearningPathwaysRow(
          pathways: dodosoCats.map((c) => LearningPathway(
            title: c.$2,
            subtitle: c.$3,
            icon: c.$4,
            gradient: c.$5,
            onTap: () {
              if (c.$1 == 'darasa_huru') {
                app.navigate(AppScreen.darasaHuru);
              } else {
                app.navigate(AppScreen.contentList,
                    contentSection: ContentSections.dodoso,
                    contentCategory: c.$1);
              }
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMakalaSection(BuildContext context, AppProvider app) {
    final content = context.watch<ContentService>();
    final posts = content.allMakalaPosts;

    return _buildPostListSection(
      context,
      app,
      title: 'Makala',
      subtitle: 'Machapisho yote kutoka Dodoso, Chagua Mada, Vyakula na Jifunze',
      posts: posts,
      section: ContentSections.allMakala,
      showSectionOnCards: true,
      headerPadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      onViewAll: () {
        app.selectedContentCategory = null;
        app.navigate(
          AppScreen.contentList,
          contentSection: ContentSections.allMakala,
        );
      },
    );
  }

  Widget _buildPostListSection(
    BuildContext context,
    AppProvider app, {
    required String title,
    required String subtitle,
    required List<ContentPost> posts,
    required String section,
    EdgeInsets headerPadding = const EdgeInsets.fromLTRB(20, 12, 20, 10),
    bool showSectionOnCards = false,
    VoidCallback? onViewAll,
  }) {
    if (posts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          padding: headerPadding,
          actionLabel: 'Zote',
          onAction: onViewAll ??
              () => app.navigate(
                    AppScreen.contentList,
                    contentSection: section,
                  ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (var i = 0; i < posts.length; i++)
                ContentPostCard(
                  post: posts[i],
                  showSectionLabel: showSectionOnCards,
                  onTap: () => openContentPost(context, posts[i]),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDarasaHuru(BuildContext context, AppProvider app) {
    final lessons = app.lessonService;
    if (lessons.isSyncing && lessons.publishedLessons.isEmpty) {
      return Column(
        children: [
          const SectionHeader(
            title: 'Darasa Huru',
            subtitle: 'Masomo ya kila siku kutoka kwa wataalamu wetu',
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ShimmerLoading(child: DarasaCardSkeleton()),
          ),
        ],
      );
    }

    final lesson = lessons.todayLesson;
    if (lesson == null) return const SizedBox.shrink();

    return Column(
      children: [
        const SectionHeader(
          title: 'Darasa Huru',
          subtitle: 'Masomo ya kila siku kutoka kwa wataalamu wetu',
          padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
        ),
        DarasaHuruCard(
          lesson: lesson,
          onTap: () => app.navigate(
            AppScreen.darasaHuru,
            lessonId: lesson.id,
          ),
          onViewAll: () => app.navigate(AppScreen.darasaHuru),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, AppProvider app) {
    final cats = [
      (Icons.spa, 'Mimea', 'mimea', const [Color(0xFFECFDF5), Color(0xFFD1FAE5)]),
      (Icons.female, 'Wanawake', 'wanawake', const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)]),
      (Icons.child_care, 'Watoto', 'watoto', const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)]),
      (Icons.male, 'Wanaume', 'wanaume', const [Color(0xFFF5F3FF), Color(0xFFEDE9FE)]),
    ];

    return Column(
      children: [
        const SectionHeader(
          title: 'Chagua Mada',
          subtitle: 'Gusa mada ili kuanza somo lako',
          padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: cats.map((cat) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => app.navigate(
                        AppScreen.contentList,
                        contentSection: ContentSections.chaguaMada,
                        contentCategory: cat.$3,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.forest.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: cat.$4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(cat.$1, size: 22, color: AppColors.forest),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cat.$2,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ContentSearchTile extends StatelessWidget {
  const _ContentSearchTile({required this.post, required this.onTap});

  final ContentPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                      if (post.excerpt.isNotEmpty)
                        Text(
                          post.excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.gray400),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.forest.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonSearchTile extends StatelessWidget {
  const _LessonSearchTile({required this.lesson, required this.onTap});

  final DailyLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forest,
                        ),
                      ),
                      if (lesson.excerpt.isNotEmpty)
                        Text(
                          lesson.excerpt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.gray400),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.forest.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
