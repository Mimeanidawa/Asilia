import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../utils/category_visual.dart';
import '../utils/content_tag_style.dart';
import '../utils/premium_content_flow.dart';
import '../utils/responsive.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/content_post_card.dart';
import '../widgets/pull_to_refresh.dart';

class ContentListScreen extends StatefulWidget {
  const ContentListScreen({super.key});

  @override
  State<ContentListScreen> createState() => _ContentListScreenState();
}

class _FilterChipData {
  const _FilterChipData(this.id, this.label, this.icon, {this.color});
  final String id;
  final String label;
  final IconData icon;
  final Color? color;
}

class _ContentListScreenState extends State<ContentListScreen> {
  String _filter = 'zote';

  @override
  void initState() {
    super.initState();
    final app = context.read<AppProvider>();
    final category = app.selectedContentCategory;
    if (category != null && category.isNotEmpty) {
      _filter = category;
    }
  }

  List<_FilterChipData> _chipsFor(String section) {
    if (section == ContentSections.allMakala) {
      return const [
        _FilterChipData('zote', 'Zote', Icons.auto_stories_rounded),
        _FilterChipData(ContentSections.dodoso, 'Dodoso', Icons.forum_rounded),
        _FilterChipData(ContentSections.chaguaMada, 'Chagua Mada', Icons.tune_rounded),
        _FilterChipData(ContentSections.vyakulaMatunda, 'Vyakula', Icons.restaurant_rounded),
        _FilterChipData(ContentSections.jifunze, 'Jifunze', Icons.menu_book_rounded),
      ];
    }

    final categories = switch (section) {
      ContentSections.dodoso => ContentSections.dodosoCategories,
      ContentSections.chaguaMada => ContentSections.chaguaMadaCategories,
      ContentSections.vyakulaMatunda => ContentSections.vyakulaMatundaCategories,
      ContentSections.jifunze => ContentSections.jifunzeCategories,
      _ => const <String>[],
    };
    if (categories.isEmpty) return const [];

    return [
      const _FilterChipData('zote', 'Zote', Icons.grid_view_rounded),
      ...categories.map(
        (c) => _FilterChipData(
          c,
          ContentSections.categoryLabel(c),
          _iconForCategory(c),
          color: ContentTagStyle.colorFor(c),
        ),
      ),
    ];
  }

  List<ContentPost> _filtered(ContentService content, String section, String? lockedCategory) {
    var posts = content.postsForSection(section, category: lockedCategory);
    if (_filter == 'zote' || lockedCategory != null) return posts;

    if (section == ContentSections.allMakala) {
      return posts.where((p) => p.section == _filter).toList();
    }
    return posts.where((p) => p.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final content = context.watch<ContentService>();
    final section = app.selectedContentSection ?? ContentSections.dodoso;
    final lockedCategory = app.selectedContentCategory;

    final chips = lockedCategory == null ? _chipsFor(section) : const <_FilterChipData>[];
    final posts = _filtered(content, section, lockedCategory);
    final title = _sectionTitle(section, lockedCategory);
    final subtitle = _sectionSubtitle(section, lockedCategory);

    final featured = posts.isNotEmpty ? posts.first : null;
    final rest = featured == null ? const <ContentPost>[] : posts.skip(1).toList();
    final columns = Responsive.listColumns(context);
    final gutter = Responsive.horizontalGutter(context);

    return SizedBox.expand(
      child: Column(
        children: [
          _MakalaHeader(
            title: title,
            subtitle: subtitle,
            count: posts.length,
            category: lockedCategory ?? section,
            onBack: app.goBack,
          ),
          if (chips.isNotEmpty)
            _FilterRail(
              chips: chips,
              selected: _filter,
              onSelect: (id) => setState(() => _filter = id),
            ),
          Expanded(
            child: PullToRefresh(
              onRefresh: () => AppRefresh.catalog(context),
              child: posts.isEmpty
                  ? _EmptyMakala(
                      loading: content.isLoading,
                      category: lockedCategory ?? (_filter == 'zote' ? null : _filter),
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (featured != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                gutter,
                                16,
                                gutter,
                                rest.isEmpty
                                    ? Responsive.scrollBottomPadding(
                                        context,
                                        extra: 12,
                                      )
                                    : 8,
                              ),
                              child: ContentFeaturedCard(
                                post: featured,
                                height: 300,
                                showSectionLabel:
                                    section == ContentSections.allMakala,
                                onTap: () => openContentPost(context, featured),
                              ),
                            ),
                          ),
                        if (rest.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                gutter + 4,
                                featured == null ? 18 : 16,
                                gutter,
                                8,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    featured == null ? title : 'Makala zaidi',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.forest,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${rest.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.forest
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (rest.isNotEmpty && columns == 1)
                          SliverToBoxAdapter(
                            child: ColoredBox(
                              color: AppColors.surfaceElevated,
                              child: Column(
                                children: [
                                  for (var i = 0; i < rest.length; i++)
                                    ContentPostCard(
                                      post: rest[i],
                                      showSectionLabel: section ==
                                          ContentSections.allMakala,
                                      margin: EdgeInsets.zero,
                                      animationIndex: i,
                                      onTap: () =>
                                          openContentPost(context, rest[i]),
                                    ),
                                  SizedBox(
                                    height: Responsive.scrollBottomPadding(
                                      context,
                                      extra: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (rest.isNotEmpty && columns > 1)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              gutter,
                              0,
                              gutter,
                              Responsive.scrollBottomPadding(
                                context,
                                extra: 12,
                              ),
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.82,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => ContentPostCard(
                                  post: rest[i],
                                  showSectionLabel:
                                      section == ContentSections.allMakala,
                                  vertical: true,
                                  margin: EdgeInsets.zero,
                                  animationIndex: i,
                                  onTap: () =>
                                      openContentPost(context, rest[i]),
                                ),
                                childCount: rest.length,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String? _sectionSubtitle(String section, String? category) {
    if (category != null && ContentService.sharedCategories.contains(category)) {
      return 'Makala zote za ${ContentSections.categoryLabel(category)}';
    }
    if (section == ContentSections.allMakala) {
      return 'Machapisho ya dawa asili kutoka sehemu zote';
    }
    return ContentSections.sectionLabel(section);
  }

  String _sectionTitle(String section, String? category) {
    if (category != null) return ContentSections.categoryLabel(category);
    switch (section) {
      case ContentSections.dodoso:
        return 'Dodoso';
      case ContentSections.chaguaMada:
        return 'Chagua Mada';
      case ContentSections.vyakulaMatunda:
        return 'Vyakula na Matunda';
      case ContentSections.jifunze:
        return 'Jifunze';
      case ContentSections.allMakala:
        return 'Makala';
      default:
        return 'Maudhui';
    }
  }
}

IconData _iconForCategory(String category) => CategoryVisual.iconFor(category);

class _MakalaHeader extends StatelessWidget {
  const _MakalaHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onBack,
    this.category,
  });

  final String title;
  final String? subtitle;
  final int count;
  final VoidCallback onBack;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.headerSheen,
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.05)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
        child: Row(
          children: [
            CircleBackButton(onPressed: onBack),
            const SizedBox(width: 12),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: CategoryVisual.gradientFor(category),
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forest.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                CategoryVisual.iconFor(category),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                      height: 1.1,
                      letterSpacing: -0.55,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.forest.withValues(alpha: 0.5),
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emerald800,
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 260.ms);
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.chips,
    required this.selected,
    required this.onSelect,
  });

  final List<_FilterChipData> chips;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.06)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          final isOn = selected == chip.id;
          final accent = chip.color ?? AppColors.forest;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(chip.id),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isOn ? accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOn
                        ? Colors.transparent
                        : AppColors.forest.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      chip.icon,
                      size: 15,
                      color: isOn ? Colors.white : accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isOn ? Colors.white : AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyMakala extends StatelessWidget {
  const _EmptyMakala({required this.loading, this.category});

  final bool loading;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final label = category == null
        ? 'Hakuna makala bado'
        : 'Hakuna makala za ${ContentSections.categoryLabel(category!)} bado';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.48,
          child: Center(
            child: loading
                ? const CircularProgressIndicator(color: AppColors.forest)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_stories_outlined,
                          size: 32,
                          color: AppColors.emerald700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Vuta chini kusasisha au rudi baadaye',
                        style: TextStyle(color: AppColors.gray400, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
