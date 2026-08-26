import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../services/notification_center_service.dart';
import '../theme/app_colors.dart';
import '../utils/content_search.dart';
import '../widgets/api_carousel.dart';
import '../widgets/app_screen_message_banner.dart';
import '../widgets/carousel_content_picker_sheet.dart';
import '../widgets/app_drawer.dart';
import '../widgets/content_post_card.dart';
import '../widgets/darasa_huru_carousel.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/learning_pathways_row.dart';
import '../utils/app_refresh.dart';
import '../utils/premium_content_flow.dart';
import '../utils/responsive.dart';
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

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final content = context.watch<ContentService>();
    final q = _searchQuery.trim();
    final isSearching = q.isNotEmpty;

    final searchHits = isSearching
        ? ContentSearch.search(
            query: _searchQuery,
            content: content,
            lessons: app.lessonService,
          )
        : <ContentSearchHit>[];
    final filteredPosts = searchHits
        .where((h) => h.kind == ContentSearchHitKind.post)
        .map((h) => h.post!)
        .toList();
    final filteredLessons = searchHits
        .where((h) => h.kind == ContentSearchHitKind.lesson)
        .map((h) => h.lesson!)
        .toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: Column(
          children: [
            _buildHeader(context, app),
            const AppScreenMessageBanner(),
            _buildSearchBar(context),
            Expanded(
              child: isSearching
                  ? _buildSearchResultsScroll(
                      context,
                      app,
                      filteredPosts,
                      filteredLessons,
                    )
                  : PullToRefresh(
                      onRefresh: () => AppRefresh.catalog(context),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: Responsive.scrollBottomPadding(context, extra: 8),
                        ),
                        children: [
                          _buildHeroCarousel(context),
                          const StatsStrip(),
                          _buildLearningPathways(context, app),
                          _buildDarasaHuru(context, app),
                          _buildCategoryGrid(context, app),
                          _buildVyakulaSection(context, app),
                          _buildMakalaSection(context, app),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.94),
        boxShadow: AppColors.elevationSm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.forest, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forest.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Dawa Asili',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.forest,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.forest),
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

  Widget _buildSearchBar(BuildContext context) {
    final showRecents = _isInputFocused &&
        _searchQuery.trim().isEmpty &&
        _recentSearches.isNotEmpty;

    return Material(
      color: AppColors.surfaceElevated.withValues(alpha: 0.98),
      elevation: _isInputFocused ? 4 : 0,
      shadowColor: AppColors.cardShadow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: _isInputFocused ? AppColors.elevationSm : null,
                border: Border.all(
                  color: _isInputFocused
                      ? AppColors.emerald700.withValues(alpha: 0.55)
                      : AppColors.forest.withValues(alpha: 0.08),
                  width: _isInputFocused ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: _commitSearch,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest,
                ),
                decoration: InputDecoration(
                  hintText: 'Tafuta mimea, mizizi, miti, masomo...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.forest.withValues(alpha: 0.38),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 22,
                    color: _isInputFocused
                        ? AppColors.emerald700
                        : AppColors.forest.withValues(alpha: 0.45),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Futa utafutaji',
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.forest.withValues(alpha: 0.5),
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (showRecents) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.emerald50.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.forest.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Utafutaji wa hivi karibuni',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearRecentSearches,
                          child: const Text(
                            'Futa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ..._recentSearches.map(
                      (term) => Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            _searchController.text = term;
                            setState(() {
                              _searchQuery = term;
                              _isInputFocused = false;
                            });
                            _searchFocus.unfocus();
                            _commitSearch(term);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history_rounded,
                                  size: 16,
                                  color: AppColors.forest.withValues(alpha: 0.35),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    term,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.north_west_rounded,
                                  size: 14,
                                  color: AppColors.forest.withValues(alpha: 0.25),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsScroll(
    BuildContext context,
    AppProvider app,
    List<ContentPost> posts,
    List<DailyLesson> lessons,
  ) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        Responsive.scrollBottomPadding(context, extra: 16),
      ),
      children: [
        _buildSearchResults(context, app, posts, lessons),
      ],
    );
  }

  Widget _buildVyakulaSection(BuildContext context, AppProvider app) {
    final content = context.watch<ContentService>();
    final cats = [
      ('matunda', 'Matunda', Icons.apple_rounded, const [Color(0xFFF7F1E8), Color(0xFFEDE3D4)]),
      ('mizizi', 'Mizizi', Icons.grass_rounded, const [Color(0xFFEDF5F0), Color(0xFFD7E8DE)]),
      ('miti', 'Miti', Icons.park_rounded, const [Color(0xFFEEF4EF), Color(0xFFDCE8DF)]),
      ('vyakula', 'Vyakula', Icons.restaurant_rounded, const [Color(0xFFEFF5F8), Color(0xFFDDE9F0)]),
      ('mimea', 'Mimea', Icons.spa_rounded, const [Color(0xFFF0F3EF), Color(0xFFE0E7E2)]),
    ];

    return Column(
      children: [
        SectionHeader(
          title: 'Vyakula na Matunda',
          subtitle: 'Makala kuhusu chakula na matunda ya asili',
          badge: '${content.vyakulaMatundaPosts.length} makala',
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          actionLabel: 'Zote',
          onAction: () => app.navigate(
            AppScreen.contentList,
            contentSection: ContentSections.vyakulaMatunda,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalGutter(context)),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cats.map((cat) {
              final count = content.countForCategory(cat.$1);
              return _VyakulaChip(
                label: cat.$2,
                icon: cat.$3,
                colors: cat.$4,
                count: count,
                onTap: () => app.navigate(
                  AppScreen.contentList,
                  contentSection: ContentSections.vyakulaMatunda,
                  contentCategory: cat.$1,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    AppProvider app,
    List<ContentPost> posts,
    List<DailyLesson> lessons,
  ) {
    final total = posts.length + lessons.length;
    final query = _searchQuery.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                total > 0
                    ? 'Matokeo kwa "$query"'
                    : 'Hakuna matokeo kwa "$query"',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (total > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.emerald700.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  '$total yamepatikana',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald800,
                  ),
                ),
              ),
          ],
        ),
        if (lessons.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SearchSectionLabel(icon: Icons.school_rounded, label: 'Masomo'),
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
          const SizedBox(height: 18),
          _SearchSectionLabel(icon: Icons.article_outlined, label: 'Makala'),
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
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 44,
                  color: AppColors.gray400.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  'Jaribu neno lingine — mimea, mizizi, miti, au somo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.gray400,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHeroCarousel(BuildContext context) {
    final content = context.watch<ContentService>();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ApiCarousel(
        slides: content.carousels,
        height: 236,
        autoPlay: true,
        onSlideTap: (slide) => _handleCarouselTap(context, slide),
      ),
    );
  }

  void _handleCarouselTap(BuildContext context, CarouselSlide slide) {
    showCarouselContentPicker(context, slide: slide);
  }

  Widget _buildLearningPathways(BuildContext context, AppProvider app) {
    final content = context.watch<ContentService>();
    final dodosoCats = [
      ('darasa_huru', 'Darasa Huru', 'Somo la kila siku', Icons.school_rounded, const [Color(0xFF0A1F1A), Color(0xFF163D32)]),
      ('mizizi', 'Mizizi', 'Mizizi ya dawa asili', Icons.grass_rounded, const [Color(0xFF145C3E), Color(0xFF1B7A52)]),
      ('miti', 'Miti', 'Miti na faida zake', Icons.park_rounded, const [Color(0xFF163D32), Color(0xFF0A1F1A)]),
      ('matunda', 'Matunda', 'Matunda ya asili', Icons.apple_rounded, const [Color(0xFF8F5530), Color(0xFFC17A45)]),
      ('mimea', 'Lishe', 'Lishe bora', Icons.restaurant_menu_rounded, const [Color(0xFF1A4A5C), Color(0xFF2A6B7A)]),
    ];

    return Column(
      children: [
        SectionHeader(
          title: 'Dodoso',
          subtitle: 'Gusa Aina ili kuona makala zote',
          badge: '${content.dodosoPosts.length} makala',
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        ),
        LearningPathwaysRow(
          pathways: dodosoCats.map((c) => LearningPathway(
            title: c.$2,
            subtitle: c.$3,
            icon: c.$4,
            gradient: c.$5,
            count: c.$1 == 'darasa_huru'
                ? null
                : content.countForCategory(c.$1),
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
    // Prefer covers so the feed looks visual; text-only posts still appear after.
    final posts = [...content.allMakalaPosts]..sort((a, b) {
      final ai = a.displayImageUrl.trim().isEmpty ? 1 : 0;
      final bi = b.displayImageUrl.trim().isEmpty ? 1 : 0;
      return ai.compareTo(bi);
    });

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
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _EmptySectionHint(title: title, subtitle: subtitle),
      );
    }

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
          padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalGutter(context)),
          child: Responsive.listColumns(context) == 1
              ? Column(
                  children: [
                    for (var i = 0; i < posts.length; i++)
                      ContentPostCard(
                        post: posts[i],
                        showSectionLabel: showSectionOnCards,
                        animationIndex: i,
                        onTap: () => openContentPost(context, posts[i]),
                      ),
                  ],
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.listColumns(context),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, i) => ContentPostCard(
                    post: posts[i],
                    showSectionLabel: showSectionOnCards,
                    margin: EdgeInsets.zero,
                    animationIndex: i,
                    onTap: () => openContentPost(context, posts[i]),
                  ),
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

    final published = lessons.publishedLessons;
    if (published.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(
          title: 'Darasa Huru',
          subtitle: 'Masomo kutoka kwa wataalamu — yanazunguka kila mara',
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          actionLabel: 'Zote',
          onAction: () => app.navigate(AppScreen.darasaHuru),
        ),
        DarasaHuruCarousel(
          lessons: published,
          onOpen: (lesson) => app.navigate(
            AppScreen.darasaHuru,
            lessonId: lesson.id,
          ),
        ),
      ],
    );
  }

  Widget _categoryTile(
    BuildContext context,
    AppProvider app,
    (IconData, String, String, List<Color>) cat,
    int count,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => app.navigate(
            AppScreen.contentList,
            contentSection: ContentSections.chaguaMada,
            contentCategory: cat.$3,
          ),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.forest.withValues(alpha: 0.04)),
              boxShadow: AppColors.elevationSm,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cat.$4,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(cat.$1, size: 22, color: AppColors.forest),
                ),
                const SizedBox(height: 10),
                Text(
                  cat.$2,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (count > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.emerald800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.92, 0.92));
  }

  Widget _buildCategoryGrid(BuildContext context, AppProvider app) {
    final content = context.watch<ContentService>();
    final cats = [
      (Icons.spa, 'Mimea', 'mimea', const [Color(0xFFEDF5F0), Color(0xFFD7E8DE)]),
      (Icons.female, 'Wanawake', 'wanawake', const [Color(0xFFF7F1E8), Color(0xFFEDE3D4)]),
      (Icons.child_care, 'Watoto', 'watoto', const [Color(0xFFEFF5F8), Color(0xFFDDE9F0)]),
      (Icons.male, 'Wanaume', 'wanaume', const [Color(0xFFF0F3EF), Color(0xFFE0E7E2)]),
    ];

    return Column(
      children: [
        SectionHeader(
          title: 'Chagua Mada',
          subtitle: 'Gusa mada ili kuanza somo lako',
          badge: '${content.chaguaMadaPosts.length} makala',
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalGutter(context)),
          child: Responsive.isPhone(context)
              ? Row(
                  children: [
                    for (var i = 0; i < cats.length; i++)
                      Expanded(
                        child: _categoryTile(
                          context,
                          app,
                          cats[i],
                          content.chaguaMadaPosts
                              .where((p) => p.category == cats[i].$3)
                              .length,
                          i,
                        ),
                      ),
                  ],
                )
              : GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: [
                    for (var i = 0; i < cats.length; i++)
                      _categoryTile(
                        context,
                        app,
                        cats[i],
                        content.chaguaMadaPosts
                            .where((p) => p.category == cats[i].$3)
                            .length,
                        i,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _VyakulaChip extends StatelessWidget {
  const _VyakulaChip({
    required this.label,
    required this.icon,
    required this.colors,
    required this.count,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.05)),
            boxShadow: AppColors.elevationSm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: AppColors.forest),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                    if (count > 0)
                      Text(
                        '$count makala',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald800,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.055)),
      ),
      child: Column(
        children: [
          Icon(Icons.article_outlined, size: 36, color: AppColors.gray400),
          const SizedBox(height: 12),
          Text(
            'Hakuna makala za $title bado',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
}

class _SearchSectionLabel extends StatelessWidget {
  const _SearchSectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.emerald800),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.emerald800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ContentSearchTile extends StatelessWidget {
  const _ContentSearchTile({
    required this.post,
    required this.onTap,
  });

  final ContentPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
              boxShadow: AppColors.elevationSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.article_outlined,
                    size: 20,
                    color: AppColors.emerald800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                      if (post.excerpt.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            post.excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.forest.withValues(alpha: 0.35),
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
  const _LessonSearchTile({
    required this.lesson,
    required this.onTap,
  });

  final DailyLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
              boxShadow: AppColors.elevationSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: AppColors.emerald800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                      if (lesson.excerpt.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            lesson.excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                              height: 1.35,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.forest.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
