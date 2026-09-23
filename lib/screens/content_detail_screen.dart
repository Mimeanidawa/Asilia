import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/ads_service.dart';
import '../services/content_service.dart';
import '../services/dawa_order_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../utils/premium_content_flow.dart';
import '../widgets/herb_image.dart';
import '../widgets/makala_ad_gate.dart';
import '../widgets/makala_ads.dart';
import '../widgets/remove_ads_promo.dart';
import '../widgets/paid_makala_badge.dart';
import '../widgets/premium_makala_gate.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/rich_content_view.dart';
import '../widgets/exclusive_product_banner.dart';
import '../widgets/fullscreen_image_viewer.dart';
import '../widgets/screen_header.dart';

class ContentDetailScreen extends StatefulWidget {
  const ContentDetailScreen({super.key});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  ContentPost? _post;
  bool _loading = true;
  bool _premiumModalShown = false;
  bool _adUnlocked = false;
  String? _adUnlockedForId;
  final ScrollController _scrollController = ScrollController();
  bool _showTopProductBanner = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final app = context.read<AppProvider>();
    final content = context.read<ContentService>();
    final user = context.read<UserService>();
    final ads = context.read<AdsService>();
    final id = app.selectedContentId;
    if (id == null || id.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Reset ad unlock when opening a different makala.
    if (_adUnlockedForId != id) {
      _adUnlocked = false;
      _adUnlockedForId = id;
      _premiumModalShown = false;
    }

    unawaitedAdsPreload(ads);

    var post = await content.fetchPost(id, userToken: user.token);
    if (post == null) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      post = await content.fetchPost(id, userToken: user.token);
    }
    if (!mounted) return;

    setState(() {
      _post = post;
      _loading = false;
    });

    _maybeShowPremiumModal(post, user);
  }

  void unawaitedAdsPreload(AdsService ads) {
    ads.initialize().then((_) => ads.preload());
  }

  void _maybeShowPremiumModal(ContentPost? post, UserService user) {
    if (post == null || _premiumModalShown) return;
    if (!post.isPremium || user.canReadContent(post)) return;

    _premiumModalShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showPremiumMakalaModal(
        context,
        post: post,
        onUnlock: _purchase,
      );
    });
  }

  Future<void> _refresh() async {
    await AppRefresh.catalog(context);
    await _load();
  }

  Future<void> _purchase() async {
    final post = _post!;
    final ok = await purchasePremiumContent(
      context,
      post: post,
      onSuccess: _load,
    );
    if (ok && mounted) setState(() => _premiumModalShown = true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = context.watch<UserService>();
    final ads = context.read<AdsService>();
    final orderService = context.watch<DawaOrderService>();

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forest));
    }

    if (_post == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Maudhui hayapatikani', style: TextStyle(color: AppColors.gray400)),
            TextButton(onPressed: app.goBack, child: const Text('Rudi')),
          ],
        ),
      );
    }

    final post = _post!;
    final canRead = user.canReadContent(post);
    final paid = user.hasPurchasedContent(post.id);
    final needsAd = ads.shouldShowAds(user) && !_adUnlocked;
    final product = orderService.getProductForPost(post);

    if (needsAd && canRead) {
      return MakalaAdGate(
        onUnlocked: () {
          if (!mounted) return;
          setState(() {
            _adUnlocked = true;
            _adUnlockedForId = post.id;
          });
          RemoveAdsPromo.recordMakalaRead();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) RemoveAdsPromo.maybeShowFloatingModal(context);
          });
        },
        onCancel: app.goBack,
      );
    }

    return SizedBox.expand(
      child: Column(
        children: [
          _header(app),
          Expanded(
            child: PullToRefresh(
              onRefresh: _refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
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
                          fullWidth: true,
                          fitToImage: true,
                          fit: BoxFit.fitWidth,
                          borderRadius: 0,
                          fallbackLabel: post.title,
                          category: post.category ?? post.section,
                        ),
                      ).animate().fadeIn(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (paid) const PaidMakalaBadge(),
                                if (post.category != null)
                                  Text(
                                    post.categoryLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.emerald800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                              ],
                            ),
                            if (paid || post.category != null) const SizedBox(height: 8),
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.forest,
                                height: 1.2,
                              ),
                            ).animate().fadeIn(delay: 100.ms),
                            if (post.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                post.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray500,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),

                            // EXPANDABLE 3D "NUNUA DAWA HII" BOX:
                            // Hidden completely by default, expands when user taps "Nunua Dawa" below
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: ExclusiveProductBanner(
                                post: post,
                                customProduct: product,
                                onClose: () => setState(() => _showTopProductBanner = false),
                                margin: const EdgeInsets.only(top: 8, bottom: 20),
                              ),
                              crossFadeState: _showTopProductBanner
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 350),
                            ),

                            if (post.isPremium && !canRead)
                              PremiumMakalaGate(
                                post: post,
                                onUnlock: _purchase,
                              )
                            else ...[
                              if (ads.shouldShowAds(user))
                                const MakalaInlineBannerAd(),
                              RichContentView(content: post.content)
                                  .animate()
                                  .fadeIn(delay: 200.ms),
                              if (ads.shouldShowAds(user)) ...[
                                const SizedBox(height: 20),
                                const RemoveAdsInlineStrip(),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          // Unified, non-interfering bottom action dock
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StickyMakalaBuyBar(
                    product: product,
                    isExpanded: _showTopProductBanner,
                    buttonLabel: _showTopProductBanner ? 'Funga Dawa' : 'Nunua Dawa',
                    buttonIcon: _showTopProductBanner
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    onChatWithAdmin: () => app.navigate(AppScreen.askExpert),
                    onTap: () {
                      if (!_showTopProductBanner) {
                        setState(() => _showTopProductBanner = true);
                        _scrollController.animateTo(
                          160,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      } else {
                        setState(() => _showTopProductBanner = false);
                      }
                    },
                  ),
                  if (canRead && !(post.isPremium && !canRead) && ads.shouldShowAds(user)) ...[
                    const SizedBox(height: 6),
                    const MakalaBannerAd(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppProvider app) {
    final cat = _post?.categoryLabel ?? 'Makala';
    return ScreenHeader(
      title: cat.toUpperCase(),
      subtitle: 'Elimu ya Dawa Asili',
      onBack: app.goBack,
    );
  }
}
