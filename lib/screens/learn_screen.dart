import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../providers/app_provider.dart';
import '../services/ads_service.dart';
import '../services/content_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../utils/content_tag_style.dart';
import '../utils/premium_content_flow.dart';
import '../utils/responsive.dart';
import '../widgets/content_post_card.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/herb_image.dart';
import '../widgets/makala_ad_gate.dart';
import '../widgets/makala_ads.dart';
import '../widgets/remove_ads_promo.dart';
import '../widgets/paid_makala_badge.dart';
import '../widgets/premium_makala_gate.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/rich_content_view.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _selectedCat = 'Zote';
  ContentPost? _activePost;
  bool _opening = false;

  static const _categories = <_LearnCategory>[
    _LearnCategory('Zote', null, Icons.auto_stories_rounded),
    _LearnCategory('Matunda', 'matunda', Icons.spa_rounded),
    _LearnCategory('Mizizi', 'mizizi', Icons.grass_rounded),
    _LearnCategory('Miti', 'miti', Icons.park_rounded),
    _LearnCategory('Mimea', 'mimea', Icons.eco_rounded),
    _LearnCategory('Vyakula', 'vyakula', Icons.restaurant_rounded),
  ];

  List<ContentPost> _filtered(ContentService content) {
    if (_selectedCat == 'Zote') return content.jifunzePosts;
    final cat = _categories.where((c) => c.label == _selectedCat).firstOrNull;
    if (cat?.key == null) return content.jifunzePosts;
    return content.postsForCategory(cat!.key!);
  }

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentService>();
    final user = context.watch<UserService>();
    final filtered = _filtered(content);

    if (_activePost != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _closePost();
        },
        child: _ArticleReader(
          post: _activePost!,
          user: user,
          loading: _opening,
          onClose: _closePost,
          onRefresh: () async {
            await AppRefresh.catalog(context);
            final full = await content.fetchPost(
              _activePost!.id,
              userToken: user.token,
            );
            if (full != null && mounted) setState(() => _activePost = full);
          },
          onPurchase: () => purchasePremiumContent(
            context,
            post: _activePost!,
            onSuccess: () async {
              final full = await content.fetchPost(
                _activePost!.id,
                userToken: user.token,
              );
              if (full != null && mounted) setState(() => _activePost = full);
            },
          ),
        ),
      );
    }

    final featured = _selectedCat == 'Zote' && filtered.length > 1
        ? filtered.first
        : null;
    final rest = featured == null
        ? filtered
        : filtered.skip(1).toList();

    return SizedBox.expand(
      child: Column(
        children: [
          _LibraryHeader(count: content.jifunzePosts.length),
          _CategoryRail(
            categories: _categories,
            selected: _selectedCat,
            onSelect: (label) => setState(() => _selectedCat = label),
          ),
          Expanded(
            child: PullToRefresh(
              onRefresh: () => AppRefresh.catalog(context),
              child: content.jifunzePosts.isEmpty && _selectedCat == 'Zote'
                  ? _EmptyLibrary(loading: content.isLoading)
                  : filtered.isEmpty
                      ? _EmptyCategory(label: _selectedCat)
                      : CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            if (featured != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    Responsive.horizontalGutter(context),
                                    18,
                                    Responsive.horizontalGutter(context),
                                    8,
                                  ),
                                  child: ContentFeaturedCard(
                                    post: featured,
                                    onTap: () => _openPost(featured, user),
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  Responsive.horizontalGutter(context) + 4,
                                  featured == null ? 18 : 14,
                                  Responsive.horizontalGutter(context),
                                  10,
                                ),
                                child: _SectionLabel(
                                  title: featured == null
                                      ? _selectedCat
                                      : 'Makala zaidi',
                                  count: rest.length,
                                ),
                              ),
                            ),
                            if (Responsive.listColumns(context) == 1)
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  Responsive.horizontalGutter(context),
                                  0,
                                  Responsive.horizontalGutter(context),
                                  Responsive.scrollBottomPadding(context, extra: 12),
                                ),
                                sliver: SliverList.separated(
                                  itemCount: rest.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, i) => ContentPostCard(
                                    post: rest[i],
                                    animationIndex: i,
                                    margin: EdgeInsets.zero,
                                    onTap: () => _openPost(rest[i], user),
                                  ),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: EdgeInsets.fromLTRB(
                                  Responsive.horizontalGutter(context),
                                  0,
                                  Responsive.horizontalGutter(context),
                                  Responsive.scrollBottomPadding(context, extra: 12),
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        Responsive.listColumns(context),
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 0.92,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, i) => ContentPostCard(
                                      post: rest[i],
                                      animationIndex: i,
                                      vertical: true,
                                      margin: EdgeInsets.zero,
                                      onTap: () => _openPost(rest[i], user),
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

  void _openPost(ContentPost post, UserService user) {
    if (needsPremiumUnlock(user, post)) {
      showPremiumUnlockForPost(
        context,
        post: post,
        onUnlocked: () => _showPost(post),
      );
      return;
    }
    _showPost(post);
  }

  Future<void> _showPost(ContentPost post) async {
    setState(() {
      _activePost = post;
      _opening = true;
    });
    context.read<AppProvider>().setBottomNavSuppressed(true);

    final full = await context.read<ContentService>().fetchPost(
          post.id,
          userToken: context.read<UserService>().token,
        );
    if (!mounted) return;
    setState(() {
      if (full != null) _activePost = full;
      _opening = false;
    });
  }

  void _closePost() {
    setState(() {
      _activePost = null;
      _opening = false;
    });
    context.read<AppProvider>().setBottomNavSuppressed(false);
  }
}

class _LearnCategory {
  const _LearnCategory(this.label, this.key, this.icon);
  final String label;
  final String? key;
  final IconData icon;
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(gradient: AppColors.accentGlow),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jifunze',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                    height: 1.1,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Maktaba ya maarifa ya dawa asili',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.elevationSm,
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
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<_LearnCategory> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.04)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isOn = selected == cat.label;
          final accent = cat.key == null
              ? AppColors.forest
              : ContentTagStyle.colorFor(cat.key!);
          return GestureDetector(
            onTap: () => onSelect(cat.label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isOn ? AppColors.forest : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isOn
                      ? Colors.transparent
                      : AppColors.forest.withValues(alpha: 0.06),
                ),
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: 0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    cat.icon,
                    size: 15,
                    color: isOn ? Colors.white : accent,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isOn ? Colors.white : AppColors.forest,
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.forest,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Text(
          '$count makala',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.gray400,
          ),
        ),
      ],
    );
  }
}


class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}


class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
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
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_outlined,
                          size: 32,
                          color: AppColors.emerald700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Maktaba bado ni tupu',
                        style: TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Vuta chini kusasisha makala',
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

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.38,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_list_off_rounded, size: 36, color: AppColors.gray400),
                const SizedBox(height: 12),
                Text(
                  'Hakuna makala za $label bado',
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ArticleReader extends StatefulWidget {
  const _ArticleReader({
    required this.post,
    required this.user,
    required this.loading,
    required this.onClose,
    required this.onRefresh,
    required this.onPurchase,
  });

  final ContentPost post;
  final UserService user;
  final bool loading;
  final VoidCallback onClose;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onPurchase;

  @override
  State<_ArticleReader> createState() => _ArticleReaderState();
}

class _ArticleReaderState extends State<_ArticleReader> {
  bool _premiumModalShown = false;
  bool _adUnlocked = false;
  bool _showFloatingChip = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdsService>().preload();
      _maybeShowPremiumModal();
    });
  }

  @override
  void didUpdateWidget(covariant _ArticleReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _premiumModalShown = false;
      _adUnlocked = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPremiumModal());
    }
  }

  void _maybeShowPremiumModal() {
    if (_premiumModalShown) return;
    final canRead = !widget.post.isPremium || widget.user.canReadContent(widget.post);
    if (canRead) return;
    _premiumModalShown = true;
    showPremiumMakalaModal(
      context,
      post: widget.post,
      onUnlock: widget.onPurchase,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final canRead = !post.isPremium || widget.user.canReadContent(post);
    final paid = widget.user.hasPurchasedContent(post.id);
    final catColor = ContentTagStyle.colorFor(post.category ?? 'jifunze');
    final top = MediaQuery.paddingOf(context).top;
    final ads = context.read<AdsService>();
    final needsAd = ads.shouldShowAds(widget.user) && !_adUnlocked && canRead;

    if (needsAd) {
      return MakalaAdGate(
        onUnlocked: () {
          if (!mounted) return;
          setState(() => _adUnlocked = true);
          RemoveAdsPromo.recordMakalaRead();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) RemoveAdsPromo.maybeShowFloatingModal(context);
          });
        },
        onCancel: widget.onClose,
      );
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    PullToRefresh(
                  onRefresh: widget.onRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 300,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              GestureDetector(
                                onTap: post.displayImageUrl.isEmpty
                                    ? null
                                    : () => openFullscreenImage(
                                          context,
                                          post.displayImageUrl,
                                          caption: post.title,
                                        ),
                                child: HerbImage(
                                  url: post.displayImageUrl,
                                  height: 300,
                                  borderRadius: 0,
                                  fullWidth: true,
                                  fit: BoxFit.cover,
                                  fallbackLabel: post.title,
                                  category: post.category ?? 'jifunze',
                                ),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x660C2A1B),
                                      Color(0x000C2A1B),
                                      Color(0xF20C2A1B),
                                    ],
                                    stops: [0, 0.42, 1],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                right: 20,
                                bottom: 28,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _GlassChip(
                                          label: post.categoryLabel.isEmpty
                                              ? 'Jifunze'
                                              : post.categoryLabel,
                                          color: catColor,
                                        ),
                                        const SizedBox(width: 8),
                                        if (paid)
                                          const PaidMakalaBadge(onDark: true),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      post.title,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.15,
                                      ),
                                    ),
                                    if (post.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        post.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Transform.translate(
                          offset: const Offset(0, -18),
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(26),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
                            child: widget.loading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 48),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.forest,
                                      ),
                                    ),
                                  )
                                : canRead
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (ads.shouldShowAds(widget.user))
                                            const MakalaInlineBannerAd(),
                                          RichContentView(
                                            content: post.content,
                                          ),
                                          if (ads.shouldShowAds(widget.user)) ...[
                                            const SizedBox(height: 20),
                                            const RemoveAdsInlineStrip(),
                                          ],
                                        ],
                                      )
                                    : PremiumMakalaGate(
                                        post: post,
                                        onUnlock: widget.onPurchase,
                                      ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: top + 8,
                  left: 12,
                  child: _ReaderBackButton(onPressed: widget.onClose),
                ),
                  ],
                ),
              ),
              if (canRead) const MakalaBannerAd(),
            ],
          ),
          if (ads.shouldShowAds(widget.user) && _adUnlocked && _showFloatingChip)
            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: RemoveAdsFloatingChip(
                onDismiss: () => setState(() => _showFloatingChip = false),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReaderBackButton extends StatelessWidget {
  const _ReaderBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
