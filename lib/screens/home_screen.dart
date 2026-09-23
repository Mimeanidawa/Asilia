import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../services/notification_center_service.dart';
import '../theme/app_colors.dart';
import '../utils/content_search.dart';
import '../data/app_data.dart' as app_catalog;
import '../widgets/condition_icon_widget.dart';
import '../widgets/api_carousel.dart';
import '../widgets/app_screen_message_banner.dart';
import '../widgets/carousel_content_picker_sheet.dart';
import '../widgets/app_drawer.dart';
import '../widgets/content_post_card.dart';
import '../widgets/darasa_huru_carousel.dart';
import '../widgets/makala_ads.dart';
import '../widgets/shimmer_loading.dart';
import '../theme/app_typography.dart';
import '../widgets/grouped_category_hub.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/stats_strip.dart';
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
  String _searchFilter = 'zote';
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
    final updated = [trimmed, ...filtered].take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('da_recent_searches', jsonEncode(updated));
    setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('da_recent_searches');
    setState(() => _recentSearches = []);
  }

  void _exitSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isInputFocused = false;
      _searchFilter = 'zote';
    });
    _searchFocus.unfocus();
  }

  void _selectSearchTerm(String term) {
    _searchController.text = term;
    setState(() {
      _searchQuery = term;
      _isInputFocused = true;
    });
    _commitSearch(term);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final content = context.watch<ContentService>();
    final q = _searchQuery.trim();
    final isSearching = q.isNotEmpty;
    final isSearchMode = _isInputFocused || isSearching;

    final searchHits = isSearching
        ? ContentSearch.search(
            query: _searchQuery,
            content: content,
            lessons: app.lessonService,
          )
        : <ContentSearchHit>[];

    final filteredConditions = searchHits
        .where((h) => h.kind == ContentSearchHitKind.condition)
        .map((h) => h.condition!)
        .toList();
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
            if (isSearchMode)
              _buildSearchFilterChips(
                isSearching: isSearching,
                conditionsCount: filteredConditions.length,
                postsCount: filteredPosts.length,
                lessonsCount: filteredLessons.length,
              ),
            Expanded(
              child: isSearchMode
                  ? (isSearching
                      ? _buildSearchResultsScroll(
                          context,
                          app,
                          filteredConditions,
                          filteredPosts,
                          filteredLessons,
                        )
                      : _buildSearchSuggestions(context, app, content))
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
                          const GroupedCategoryHub(),
                          _buildDarasaHuru(context, app),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: HomeFeedBannerAd(),
                          ),
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
    final isSearchMode = _isInputFocused || _searchQuery.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.headerSheen,
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.05)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Row(
          children: [
            isSearchMode
                ? _HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: _exitSearch,
                  )
                : _HeaderIconButton(
                    icon: Icons.menu_rounded,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  border: Border.all(
                    color: _isInputFocused
                        ? AppColors.emerald700.withValues(alpha: 0.5)
                        : AppColors.forest.withValues(alpha: 0.08),
                    width: _isInputFocused ? 1.3 : 1,
                  ),
                  boxShadow: _isInputFocused ? AppColors.elevationSm : null,
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  onSubmitted: _commitSearch,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tafuta dawa, magonjwa, makala...',
                    hintStyle: TextStyle(
                      fontSize: AppTypography.subtitle,
                      fontWeight: FontWeight.w500,
                      color: AppColors.forest.withValues(alpha: 0.4),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: _isInputFocused
                          ? AppColors.emerald700
                          : AppColors.forest.withValues(alpha: 0.45),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 38, minHeight: 38),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.forest.withValues(alpha: 0.5),
                            ),
                          )
                        : (isSearchMode
                            ? GestureDetector(
                                onTap: _exitSearch,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.forest.withValues(alpha: 0.35),
                                ),
                              )
                            : null),
                    suffixIconConstraints:
                        const BoxConstraints(minWidth: 34, minHeight: 38),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _HeaderIconButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => app.navigate(AppScreen.notifications),
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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
      ),
    );
  }

  Widget _buildRecentSearchesBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
        boxShadow: AppColors.elevationSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utafutaji wa hivi karibuni',
                style: TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald800,
                  letterSpacing: 0.2,
                ),
              ),
              GestureDetector(
                onTap: _clearRecentSearches,
                child: Text(
                  'Futa',
                  style: TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _recentSearches.map((term) {
              return PressableScale(
                onTap: () {
                  _searchController.text = term;
                  setState(() {
                    _searchQuery = term;
                    _isInputFocused = false;
                  });
                  _searchFocus.unfocus();
                  _commitSearch(term);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(AppColors.radiusPill),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: AppColors.forest,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        term,
                        style: TextStyle(
                          fontSize: AppTypography.subtitle,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forest,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterChips({
    required bool isSearching,
    required int conditionsCount,
    required int postsCount,
    required int lessonsCount,
  }) {
    final chips = [
      {'id': 'zote', 'label': isSearching ? 'Zote (${conditionsCount + postsCount + lessonsCount})' : 'Zote'},
      {'id': 'magonjwa', 'label': isSearching ? 'Magonjwa ($conditionsCount)' : 'Magonjwa'},
      {'id': 'makala', 'label': isSearching ? 'Makala ($postsCount)' : 'Makala'},
      {'id': 'masomo', 'label': isSearching ? 'Masomo ($lessonsCount)' : 'Masomo'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final id = chip['id']!;
          final label = chip['label']!;
          final selected = _searchFilter == id;

          return PressableScale(
            onTap: () => setState(() => _searchFilter = id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.forest : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
                border: Border.all(
                  color: selected ? AppColors.forest : AppColors.forest.withValues(alpha: 0.1),
                ),
                boxShadow: selected ? AppColors.elevationSm : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : AppColors.forest,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchSuggestions(
    BuildContext context,
    AppProvider app,
    ContentService content,
  ) {
    final suggestedConditions = app_catalog.conditions;
    final suggestedPosts = content.allMakalaPosts.take(4).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        Responsive.scrollBottomPadding(context, extra: 16),
      ),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          _buildRecentSearchesBar(),
          const SizedBox(height: 14),
        ],

        // Mada Maarufu Quick Tags
        const Text(
          'MADA MAARUFU ZA KUTAFUTA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.emerald800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            'Vidonda vya Tumbo',
            'Kisukari',
            'Shinikizo la Damu',
            'Mwarobaini',
            'Kikohozi na Mafua',
            'Tangawizi',
            'Magonjwa ya Ngozi',
            'Mchaichai',
          ].map((tag) {
            return PressableScale(
              onTap: () => _selectSearchTerm(tag),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppColors.radiusPill),
                  border: Border.all(color: AppColors.forest.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_rounded, size: 13, color: AppColors.emerald800),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),

        // Magonjwa Yanayotafutwa Zaidi
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MAGONJWA YANAYOTAFUTWA ZAIDI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.emerald800,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () => app.navigate(AppScreen.conditions),
              child: const Text(
                'Ona Yote >',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...suggestedConditions.take(4).map(
              (cond) => _ConditionSearchTile(
                condition: cond,
                onTap: () {
                  _commitSearch(cond.name);
                  app.navigate(AppScreen.conditions, conditionId: cond.id);
                },
              ),
            ),
        const SizedBox(height: 18),

        // Makala Zinazopendekezwa
        if (suggestedPosts.isNotEmpty) ...[
          const Text(
            'MAKALA ZINAZOPENDEKEZWA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.emerald800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...suggestedPosts.map(
            (post) => _ContentSearchTile(
              post: post,
              onTap: () {
                _commitSearch(post.title);
                openContentPost(context, post);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSearchResultsScroll(
    BuildContext context,
    AppProvider app,
    List<Condition> conditions,
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
        _buildSearchResults(context, app, conditions, posts, lessons),
      ],
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    AppProvider app,
    List<Condition> conditions,
    List<ContentPost> posts,
    List<DailyLesson> lessons,
  ) {
    final showConditions = (_searchFilter == 'zote' || _searchFilter == 'magonjwa') && conditions.isNotEmpty;
    final showPosts = (_searchFilter == 'zote' || _searchFilter == 'makala') && posts.isNotEmpty;
    final showLessons = (_searchFilter == 'zote' || _searchFilter == 'masomo') && lessons.isNotEmpty;

    final total = (_searchFilter == 'magonjwa'
        ? conditions.length
        : (_searchFilter == 'makala'
            ? posts.length
            : (_searchFilter == 'masomo'
                ? lessons.length
                : conditions.length + posts.length + lessons.length)));
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

        // Magonjwa Results Section
        if (showConditions) ...[
          const SizedBox(height: 18),
          _SearchSectionLabel(icon: Icons.monitor_heart_rounded, label: 'Magonjwa & Hali za Afya (${conditions.length})'),
          const SizedBox(height: 8),
          ...conditions.map(
            (cond) => _ConditionSearchTile(
              condition: cond,
              onTap: () {
                _commitSearch(_searchQuery);
                app.navigate(AppScreen.conditions, conditionId: cond.id);
              },
            ),
          ),
        ],

        // Makala Results Section
        if (showPosts) ...[
          const SizedBox(height: 18),
          _SearchSectionLabel(icon: Icons.article_outlined, label: 'Makala ya Dawa & Mimea (${posts.length})'),
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

        // Masomo Results Section
        if (showLessons) ...[
          const SizedBox(height: 18),
          _SearchSectionLabel(icon: Icons.school_rounded, label: 'Masomo ya Darasa Huru (${lessons.length})'),
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

        if (!showConditions && !showPosts && !showLessons)
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
                  'Hakuna matokeo yaliyopatikana kwa "$query".\nJaribu kutafuta kwa maneno haya:',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    'Vidonda vya Tumbo',
                    'Kisukari',
                    'Mwarobaini',
                    'Presha',
                    'Tangawizi',
                    'Kikohozi na Mafua',
                  ].map((sugg) {
                    return PressableScale(
                      onTap: () => _selectSearchTerm(sugg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(AppColors.radiusPill),
                          border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          sugg,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald800,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
          height: 340,
          onOpen: (lesson) => app.navigate(
            AppScreen.darasaHuru,
            lessonId: lesson.id,
          ),
        ),
      ],
    );
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

class _ConditionSearchTile extends StatelessWidget {
  const _ConditionSearchTile({
    required this.condition,
    required this.onTap,
  });

  final Condition condition;
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
              border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
              boxShadow: AppColors.elevationSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: ConditionIconWidget(type: condition.iconType),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              condition.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emerald50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${condition.remedies.length} Tiba Asili',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emerald800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        condition.shortDesc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.gray500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.emerald50.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Icon(icon, color: AppColors.forest, size: 21),
      ),
    );
  }
}
