import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_data.dart' as app_catalog;
import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../services/dawa_order_service.dart';
import '../services/notification_center_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/app_refresh.dart';
import '../utils/content_search.dart';
import '../utils/platform_fonts.dart';
import '../utils/premium_content_flow.dart';
import '../utils/responsive.dart';
import '../widgets/api_carousel.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_screen_message_banner.dart';
import '../widgets/carousel_content_picker_sheet.dart';
import '../widgets/condition_icon_widget.dart';
import '../widgets/content_post_card.dart';
import '../widgets/darasa_huru_carousel.dart';
import '../widgets/home_widgets.dart';
import '../widgets/makala_ads.dart';
import '../widgets/order_product_sheet.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_loading.dart';

/// Page gutter shared by every block on the home screen so cards, banners and
/// ads all line up on the same left/right edges.
const double _kGutter = 16;

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
      if (!mounted) return;
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
    if (saved != null && mounted) {
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
    if (mounted) setState(() => _recentSearches = updated);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('da_recent_searches');
    if (mounted) setState(() => _recentSearches = []);
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

  void _submitSearch() {
    if (_searchQuery.trim().isEmpty) {
      _searchFocus.requestFocus();
      return;
    }
    _commitSearch(_searchQuery);
    _searchFocus.unfocus();
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

    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: AppColors.cream,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.brandGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: _HeaderDecor()),
            Column(
              children: [
                SizedBox(height: topInset),
                _buildTopBar(context, app, isSearchMode),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: isSearchMode
                      ? const SizedBox(width: double.infinity, height: 8)
                      : const _BrandBlock(),
                ),
                Expanded(
                  child: _buildSheet(
                    context,
                    app,
                    content,
                    isSearchMode: isSearchMode,
                    isSearching: isSearching,
                    conditions: filteredConditions,
                    posts: filteredPosts,
                    lessons: filteredLessons,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    AppProvider app,
    bool isSearchMode,
  ) {
    final unread = context.watch<NotificationCenterService>().unreadCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isSearchMode
                  ? const Center(
                      key: ValueKey('search-title'),
                      child: Text(
                        'Tafuta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-title')),
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
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.45,
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

  // ── White sheet: search + chips + content ─────────────────────────────────

  Widget _buildSheet(
    BuildContext context,
    AppProvider app,
    ContentService content, {
    required bool isSearchMode,
    required bool isSearching,
    required List<Condition> conditions,
    required List<ContentPost> posts,
    required List<DailyLesson> lessons,
  }) {
    final Widget body;
    if (isSearchMode) {
      body = isSearching
          ? _buildSearchResultsScroll(context, app, conditions, posts, lessons)
          : _buildSearchSuggestions(context, app, content);
    } else {
      body = PullToRefresh(
        color: AppColors.brand,
        onRefresh: () => AppRefresh.catalog(context),
        child: _buildHomeFeed(context, app, content),
      );
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildSearchBar(isSearchMode),
          if (isSearchMode)
            _buildSearchFilterChips(
              isSearching: isSearching,
              conditionsCount: conditions.length,
              postsCount: posts.length,
              lessonsCount: lessons.length,
            )
          else
            _buildQuickChips(app),
          const AppScreenMessageBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isSearchMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 18, _kGutter, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isInputFocused
                ? AppColors.brand.withValues(alpha: 0.55)
                : AppColors.forest.withValues(alpha: 0.06),
            width: _isInputFocused ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _searchQuery = v),
                onSubmitted: (v) {
                  _commitSearch(v);
                  _searchFocus.unfocus();
                },
                textInputAction: TextInputAction.search,
                cursorColor: AppColors.brand,
                style: TextStyle(
                  fontSize: AppTypography.cardTitle,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forest,
                ),
                decoration: InputDecoration(
                  hintText: 'Tafuta dawa, magonjwa, makala...',
                  hintStyle: TextStyle(
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w500,
                    color: AppColors.forest.withValues(alpha: 0.4),
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.fromLTRB(18, 16, 4, 16),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: AppColors.forest.withValues(alpha: 0.4),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: PressableScale(
                onTap: _submitSearch,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChips(AppProvider app) {
    void openSection(String section) {
      app.selectedContentCategory = null;
      app.navigate(AppScreen.contentList, contentSection: section);
    }

    final items = <_QuickChip>[
      _QuickChip(
        Icons.spa_rounded,
        'Mimea',
        () => openSection(ContentSections.dodoso),
      ),
      _QuickChip(
        Icons.monitor_heart_rounded,
        'Magonjwa',
        () => app.navigate(AppScreen.conditions),
      ),
      _QuickChip(
        Icons.menu_book_rounded,
        'Makala',
        () => openSection(ContentSections.allMakala),
      ),
      _QuickChip(
        Icons.school_rounded,
        'Masomo',
        () => app.navigate(AppScreen.darasaHuru),
      ),
      _QuickChip(
        Icons.local_pharmacy_rounded,
        'Duka',
        () => app.navigate(AppScreen.dawaShop),
      ),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(_kGutter, 10, _kGutter, 10),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = items[i];
          return PressableScale(
            onTap: chip.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
                border: Border.all(
                  color: AppColors.brand.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip.icon, size: 16, color: AppColors.brand),
                  const SizedBox(width: 6),
                  Text(
                    chip.label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Home feed ─────────────────────────────────────────────────────────────

  /// Herbs / articles with images first, for the "Featured" grid.
  List<ContentPost> _featuredPosts(ContentService content, {int count = 8}) {
    final pool = content.dodosoPosts
        .where((p) => p.category != 'darasa_huru')
        .toList();
    final source = pool.isNotEmpty ? pool : content.allMakalaPosts;

    final picked = <ContentPost>[];
    for (final p in source) {
      if (p.displayImageUrl.trim().isNotEmpty) picked.add(p);
      if (picked.length >= count) return picked;
    }
    for (final p in source) {
      if (picked.length >= count) break;
      if (!picked.contains(p)) picked.add(p);
    }
    return picked;
  }

  Widget _buildHomeFeed(
    BuildContext context,
    AppProvider app,
    ContentService content,
  ) {
    final orderService = context.watch<DawaOrderService>();
    final products = orderService.products;
    final featured = _featuredPosts(content);
    final featuredIds = featured.map((p) => p.id).toSet();
    final feedPosts = content.allMakalaPosts
        .where((p) => !featuredIds.contains(p.id))
        .take(12)
        .toList();

    // Feed entries: posts with an ad slot after the 4th and 8th card.
    final entries = <ContentPost?>[];
    for (var i = 0; i < feedPosts.length; i++) {
      entries.add(feedPosts[i]);
      if (i == 3 || i == 7) entries.add(null);
    }

    const adPadding = EdgeInsets.fromLTRB(_kGutter, 14, _kGutter, 0);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (content.carousels.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: ApiCarousel(
                slides: content.carousels,
                height: 188,
                autoPlay: true,
                onSlideTap: (slide) => showCarouselContentPicker(
                  context,
                  slide: slide,
                ),
              ),
            ),
          ),

        // Featured Asili
        if (featured.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Dawa Asili',
              subtitle: 'Mimea na tiba maarufu kwa afya yako',
              padding: const EdgeInsets.fromLTRB(_kGutter + 2, 22, _kGutter, 12),
              actionLabel: 'Zote',
              onAction: () {
                app.selectedContentCategory = null;
                app.navigate(
                  AppScreen.contentList,
                  contentSection: ContentSections.dodoso,
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: FeaturedAsiliGrid(
              posts: featured,
              onOpen: (post) => openContentPost(context, post),
            ),
          ),
          const SliverToBoxAdapter(
            child: HomeFeedBannerAd(padding: adPadding),
          ),
        ] else if (content.isLoading)
          const SliverToBoxAdapter(child: _FeaturedSkeleton()),

        // Dawa shop
        if (products.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Duka la Dawa Asili',
              subtitle: 'Tiba zilizothibitishwa • Punguzo la hadi 50%',
              padding: const EdgeInsets.fromLTRB(_kGutter + 2, 22, _kGutter, 10),
              actionLabel: 'Dukani',
              onAction: () => app.navigate(AppScreen.dawaShop),
            ),
          ),
          SliverToBoxAdapter(
            child: DawaProductShelf(
              products: products,
              onBuy: (p) => OrderProductSheet.show(context, p),
            ),
          ),
        ],

        // Categories
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Gundua kwa Makundi',
            padding: const EdgeInsets.fromLTRB(_kGutter + 2, 14, _kGutter, 12),
          ),
        ),
        SliverToBoxAdapter(
          child: HomeCategoryStrip(
            onSelect: (cat) => app.navigate(
              AppScreen.contentList,
              contentSection: cat.section,
              contentCategory: cat.id,
            ),
          ),
        ),

        // Darasa Huru
        SliverToBoxAdapter(child: _buildDarasaHuru(context, app)),
        const SliverToBoxAdapter(
          child: HomeFeedBannerAd(padding: adPadding),
        ),

        // Makala feed
        if (feedPosts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Makala Mpya',
              subtitle: 'Soma na ujifunze kuhusu afya asilia',
              padding: const EdgeInsets.fromLTRB(_kGutter + 2, 22, _kGutter, 12),
              actionLabel: 'Zote',
              onAction: _openAllMakala(app),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: _kGutter),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final post = entries[i];
                if (post == null) {
                  return const HomeFeedBannerAd(
                    padding: EdgeInsets.only(bottom: 14),
                  );
                }
                return ContentPostCard(
                  post: post,
                  showSectionLabel: true,
                  animationIndex: i < 6 ? i : 0,
                  onTap: () => openContentPost(context, post),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kGutter, 4, _kGutter, 0),
              child: _SeeAllButton(
                label: 'Ona Makala Zote',
                onTap: _openAllMakala(app),
              ),
            ),
          ),
        ] else if (!content.isLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kGutter, 24, _kGutter, 0),
              child: const _EmptyFeedHint(),
            ),
          ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: Responsive.scrollBottomPadding(context, extra: 20),
          ),
        ),
      ],
    );
  }

  VoidCallback _openAllMakala(AppProvider app) => () {
        app.selectedContentCategory = null;
        app.navigate(
          AppScreen.contentList,
          contentSection: ContentSections.allMakala,
        );
      };

  Widget _buildDarasaHuru(BuildContext context, AppProvider app) {
    final lessons = app.lessonService;
    if (lessons.isSyncing && lessons.publishedLessons.isEmpty) {
      return const Column(
        children: [
          SectionHeader(
            title: 'Darasa Huru',
            subtitle: 'Masomo ya kila siku kutoka kwa wataalamu wetu',
            padding: EdgeInsets.fromLTRB(_kGutter + 2, 22, _kGutter, 10),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _kGutter),
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
          subtitle: 'Masomo kutoka kwa wataalamu wetu',
          padding: const EdgeInsets.fromLTRB(_kGutter + 2, 22, _kGutter, 10),
          actionLabel: 'Zote',
          onAction: () => app.navigate(AppScreen.darasaHuru),
        ),
        DarasaHuruCarousel(
          lessons: published,
          height: 290,
          onOpen: (lesson) => app.navigate(
            AppScreen.darasaHuru,
            lessonId: lesson.id,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchesBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 6, 0, 8),
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
      margin: const EdgeInsets.fromLTRB(_kGutter, 12, _kGutter, 6),
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
        _kGutter,
        4,
        _kGutter,
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
}

class _QuickChip {
  const _QuickChip(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Soft botanical decoration drawn behind the green header.
class _HeaderDecor extends StatelessWidget {
  const _HeaderDecor();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -70,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: -28,
              child: Transform.rotate(
                angle: 0.55,
                child: Icon(
                  Icons.eco_rounded,
                  size: 170,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              top: 56,
              left: -34,
              child: Transform.rotate(
                angle: -0.7,
                child: Icon(
                  Icons.spa_rounded,
                  size: 130,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              top: 120,
              right: 70,
              child: Transform.rotate(
                angle: 0.3,
                child: Icon(
                  Icons.energy_savings_leaf_rounded,
                  size: 58,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "DAWA ASILI — MIMEA NI DAWA!" brand lockup.
class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    final titleStyle = useSystemFonts
        ? const TextStyle(
            fontFamily: 'serif',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.8,
            height: 1.1,
          )
        : GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1.8,
            height: 1.1,
          );

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        child: Column(
          children: [
            Text('DAWA ASILI', textAlign: TextAlign.center, style: titleStyle),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Text(
                  'MIMEA NI DAWA!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.6,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 22,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 22, _kGutter, 0),
      child: ShimmerLoading(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < 4; i++)
                  SkeletonBox(
                    width: w,
                    height: w * 0.84 + 70,
                    borderRadius: BorderRadius.circular(20),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.brand.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 17,
              color: AppColors.brand,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeedHint extends StatelessWidget {
  const _EmptyFeedHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.article_outlined, size: 36, color: AppColors.gray400),
          const SizedBox(height: 12),
          const Text(
            'Hakuna makala bado',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vuta chini ili kusasisha au jaribu tena baadaye.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.gray400),
          ),
        ],
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
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
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
